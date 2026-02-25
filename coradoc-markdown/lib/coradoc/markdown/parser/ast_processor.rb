# frozen_string_literal: true

require_relative 'inline_parser'

module Coradoc
  module Markdown
    module Parser
      # Post-processes the AST produced by BlockParser.
      #
      # This processor handles:
      # - Escape sequence processing (\# -> #, \* -> *, etc.)
      # - Hard line break detection (two+ spaces at end of line)
      # - Inline element parsing (emphasis, code spans, etc.)
      #
      class AstProcessor
        # Characters that can be escaped in Markdown
        ESCAPABLE_CHARS = %w[
          ! " # $ % & ' ( ) * + , - . / : ; < = > ? @ [ \\ ] ^ _ ` { | } ~
        ].freeze

        class << self
          # Process the AST, applying all post-processing rules
          #
          # @param ast [Array] The parsed AST from BlockParser
          # @param parse_inlines [Boolean] Whether to parse inline elements
          # @return [Array] The processed AST
          def process(ast, parse_inlines: true)
            return ast if ast.nil?

            result = process_node(ast)
            result = process_inlines(result) if parse_inlines
            result
          end

          # Extract inline Kramdown elements from text
          # Returns an array of elements: text, footnote references, etc.
          def extract_inline_elements(text)
            return [text] if text.nil? || text.empty?

            elements = []
            remaining = text

            # Pattern for footnote reference: [^name]
            fn_pattern = /\[\^([^\]]+)\]/

            until remaining.empty?
              match = remaining.match(fn_pattern)
              if match
                # Add text before the match
                elements << match.pre_match unless match.pre_match.empty?
                # Add the footnote reference
                elements << { fn_ref: match[1] }
                remaining = match.post_match
              else
                # No more matches - add remaining text
                elements << remaining
                break
              end
            end

            elements.length == 1 ? elements.first : elements
          end

          # Apply typography substitutions (Kramdown extension)
          # - -- to en-dash (–)
          # - --- to em-dash (—)
          # - ... to ellipsis (…)
          def apply_typography(text)
            return text if text.nil?

            result = text.to_s
            # Order matters: --- before --
            result = result.gsub('---', '—')  # em-dash
            result = result.gsub('--', '–')   # en-dash
            result.gsub('...', '…') # ellipsis
          end

          private

          # Process a single node in the AST
          def process_node(node)
            case node
            when Array
              node.map { |child| process_node(child) }
            when Hash
              process_hash(node)
            when Parslet::Slice
              # Process escape sequences in Parslet::Slice values
              process_escapes(node.to_s)
            else
              node
            end
          end

          # Process a hash node
          def process_hash(hash)
            result = {}

            hash.each do |key, value|
              result[key] = case key
                            when :ln
                              # Process line content - detect hard line breaks and escape sequences
                              process_line_content(value)
                            when :text
                              # Process text content - may be a Hash, Array, or string
                              process_node(value)
                            when :p
                              # Process paragraph content - may contain hard line breaks
                              process_paragraph_content(value)
                            when :cell
                              # Process table cell - strip trailing whitespace
                              process_table_cell(value)
                            when :sep
                              # Process table separator - normalize to alignment indicator
                              process_table_separator(value)
                            when :table_header, :table_body, :table_body_row, :table_separator
                              # Process table elements recursively
                              process_node(value)
                            else
                              process_node(value)
                            end
            end

            result
          end

          # Process table cell content - strip trailing whitespace
          def process_table_cell(value)
            return value if value.nil?

            text = value.to_s.strip
            process_escapes(text)
          end

          # Process table separator - normalize to alignment indicator
          # "----------" -> "-" (no alignment)
          # ":-----" -> ":-" (left align)
          # "------:" -> "-:" (right align)
          # ":----:" -> ":-:" (center align)
          def process_table_separator(value)
            return value if value.nil?

            text = value.to_s
            has_left_colon = text.start_with?(':')
            has_right_colon = text.end_with?(':')

            if has_left_colon && has_right_colon
              ':-:'
            elsif has_left_colon
              ':-'
            elsif has_right_colon
              '-:'
            else
              '-'
            end
          end

          # Process line content
          # Detects hard line breaks (2+ trailing spaces) and escape sequences
          def process_line_content(value)
            return value if value.nil?

            case value
            when Parslet::Slice
            end
            text = value.to_s

            process_escapes(text)
          end

          # Process paragraph content
          # Handles arrays of lines and detects hard line breaks
          def process_paragraph_content(value)
            return value if value.nil?

            case value
            when Array
              # Array of lines - process each and detect hard breaks
              process_paragraph_lines(value)
            when Hash
              # Single line - just process it
              if value.key?(:ln)
                text = process_line_content(value[:ln])
                # Check for hard break at end
                if text.end_with?('  ')
                  spaces = text.rstrip! || text
                  trailing = text.length - spaces.length
                  text = text.rstrip
                  return [{ ln: text }, { br: ' ' * trailing }]
                end
              end
              process_node(value)
            else
              process_node(value)
            end
          end

          # Process an array of paragraph lines
          # Detects hard line breaks (lines ending with 2+ spaces)
          def process_paragraph_lines(lines)
            result = []

            lines.each_with_index do |line, _idx|
              processed = process_node(line)

              # Check if this is a line with trailing spaces (hard break indicator)
              if processed.is_a?(Hash) && processed.key?(:ln)
                text = processed[:ln].to_s
                # Check for 2+ trailing spaces
                if text.rstrip != text && text.rstrip.length < text.length
                  trailing_len = text.length - text.rstrip.length
                  if trailing_len >= 2
                    # Hard line break detected
                    stripped_text = text.rstrip
                    result << { ln: stripped_text }
                    # Add br element (inline hard break)
                    result << { br: ' ' * trailing_len }
                    next
                  end
                end
              end

              result << processed
            end

            # Remove trailing br if last element (hard break at end of paragraph is ignored)
            result.pop if result.last.is_a?(Hash) && result.last.key?(:br)

            result
          end

          # Process a text value (Parslet::Slice or String)
          # Only processes escape sequences without changing structure
          def process_text_value(value)
            return value if value.nil?

            case value
            when Parslet::Slice
            end
            process_escapes(value.to_s)
          end

          # Process escape sequences in text
          #
          # Converts \# to #, \* to *, etc.
          def process_escapes(text)
            return text if text.nil?

            # Match backslash followed by any ASCII punctuation character
            text.gsub(%r{\\([!-"#$%&'()*+,\-./:;<=>?@\[\\\]^_`{|}~])}) do
              Regexp.last_match(1)
            end
          end

          # Parse inline elements in the processed AST
          # This runs the InlineParser on text content
          def process_inlines(ast)
            return ast if ast.nil?

            inline_parser = InlineParser.new

            process_inlines_recursive(ast, inline_parser)
          end

          # Recursively process AST for inline elements
          def process_inlines_recursive(node, inline_parser)
            case node
            when Array
              # Process array, potentially flattening if inline parsing produces arrays
              result = []
              node.each do |item|
                processed = process_inlines_recursive(item, inline_parser)
                if processed.is_a?(Array) && item.is_a?(Hash) && item.key?(:ln)
                  # Inline parsing of a line produced multiple elements
                  result.concat(processed)
                else
                  result << processed
                end
              end
              result
            when Hash
              process_inlines_hash(node, inline_parser)
            else
              node
            end
          end

          # Process a hash for inline elements
          def process_inlines_hash(hash, inline_parser)
            # Skip inline parsing for code blocks - content is literal
            return { code_block: process_node(hash[:code_block]) } if hash.key?(:code_block)

            # Skip inline parsing for headings - just process escape sequences
            if hash.key?(:heading)
              result = { heading: process_node(hash[:heading]) }
              result[:text] = process_node(hash[:text]) if hash.key?(:text)
              return result
            end

            result = {}

            hash.each do |key, value|
              case key
              when :ln
                # Parse inline content for lines
                inline_result = parse_inline_content(value, inline_parser)
                if inline_result.is_a?(Hash)
                  # Result is a hash - merge it
                  if inline_result.key?(:ln)
                    # Single line with no emphasis - keep as :ln
                    result[key] = inline_result[:ln]
                  elsif inline_result.key?(:em)
                    # Emphasis found - return as the hash
                    return inline_result
                  else
                    result.merge!(inline_result)
                  end
                elsif inline_result.is_a?(Array)
                  # Multiple elements from inline parsing
                  return inline_result unless inline_result.length == 1 && inline_result.first.is_a?(Hash)

                  result.merge!(inline_result.first)

                else
                  result[key] = inline_result
                end
              when :p
                # Process paragraph content recursively
                result[key] = process_inlines_recursive(value, inline_parser)
              else
                result[key] = process_inlines_recursive(value, inline_parser)
              end
            end

            result
          end

          # Parse inline content for a text value
          def parse_inline_content(text, inline_parser)
            return { ln: text } if text.nil? || text.to_s.empty?

            text_str = text.to_s

            # First, process HTML markdown attributes (Kramdown extension)
            text_str = process_html_markdown_attr(text_str, inline_parser)

            # Parse with inline parser
            begin
              parsed = inline_parser.parse(text_str)
              return { ln: text } if parsed.nil? || parsed.empty?

              # Convert parsed result to expected format
              result = convert_inline_result(parsed)

              # Check if any emphasis was found
              has_emphasis = contains_emphasis?(result)

              if has_emphasis
                # Return emphasis wrapped in :ln to match expected structure
                if result.is_a?(Hash) && (result.key?(:em) || result.key?(:strong))
                end
                { ln: result }
              else
                # No emphasis found - join all text content back together
                joined = extract_text_content(result)
                { ln: joined }
              end
            rescue Parslet::ParseFailed
              # If parsing fails, return original text in ln structure
              { ln: text }
            end
          end

          # Process HTML markdown attribute (Kramdown extension)
          # Handles <tag markdown="X">content</tag> patterns
          # - markdown="0" - escape content (no markdown processing)
          # - markdown="1" or markdown="span" - process inline markdown
          # - markdown="block" - process block markdown
          def process_html_markdown_attr(text, inline_parser)
            return text if text.nil?

            # Pattern to match HTML tags with markdown attribute
            # Captures: tag name, markdown value, content, closing tag
            pattern = %r{<(#{HTML_TAG_PATTERN})\s+([^>]*?)markdown\s*=\s*["']([^"']+)["']([^>]*)>(.*?)</\1>}im

            text.gsub(pattern) do |_match|
              tag_name = ::Regexp.last_match(1)
              before_attrs = ::Regexp.last_match(2)
              markdown_value = ::Regexp.last_match(3).downcase
              after_attrs = ::Regexp.last_match(4)
              content = ::Regexp.last_match(5)

              processed_content = case markdown_value
                                  when '0'
                                    # Don't process markdown - escape special characters
                                    escape_html_content(content)
                                  when '1', 'span'
                                    # Process inline markdown
                                    process_inline_in_html(content, inline_parser)
                                  when 'block'
                                    # Process block-level markdown (same as span for inline context)
                                    process_inline_in_html(content, inline_parser)
                                  else
                                    # Unknown value, don't process
                                    escape_html_content(content)
                                  end

              # Reconstruct the tag without the markdown attribute
              attrs = "#{before_attrs.strip} #{after_attrs.strip}"
              attrs = attrs.strip
              attrs = " #{attrs}" unless attrs.empty?
              "<#{tag_name}#{attrs}>#{processed_content}</#{tag_name}>"
            end
          end

          # HTML tag pattern (common tags that might have markdown attribute)
          HTML_TAG_PATTERN = /\w+/

          # Process inline markdown inside HTML content
          def process_inline_in_html(content, inline_parser)
            return content if content.nil? || content.empty?

            # Check for nested HTML tags with markdown attribute first
            content = process_html_markdown_attr(content, inline_parser)

            # Parse the content as inline markdown
            begin
              parsed = inline_parser.parse(content)
              return content if parsed.nil? || parsed.empty?

              result = convert_inline_result(parsed)

              # Convert result back to string representation
              inline_result_to_string(result)
            rescue Parslet::ParseFailed
              content
            end
          end

          # Convert inline parsing result to string
          def inline_result_to_string(result)
            case result
            when Hash
              if result.key?(:em)
                "<em>#{inline_result_to_string(result[:em])}</em>"
              elsif result.key?(:strong)
                "<strong>#{inline_result_to_string(result[:strong])}</strong>"
              elsif result.key?(:code)
                "<code>#{result[:code]}</code>"
              elsif result.key?(:text)
                result[:text].to_s
              else
                result.values.map { |v| inline_result_to_string(v) }.join
              end
            when Array
              result.map { |item| inline_result_to_string(item) }.join
            else
              result.to_s
            end
          end

          # Escape HTML content for markdown="0"
          def escape_html_content(content)
            # When markdown="0", we need to preserve the content literally
            # but escape any characters that would be interpreted as markdown
            content
          end

          # Check if result contains emphasis markers
          def contains_emphasis?(result)
            case result
            when Hash
              result.key?(:em) || result.key?(:strong) ||
                result.values.any? { |v| contains_emphasis?(v) }
            when Array
              result.any? { |item| contains_emphasis?(item) }
            else
              false
            end
          end

          # Extract all text content from result, joining strings
          def extract_text_content(result)
            case result
            when Hash
              if result.key?(:em)
                extract_text_content(result[:em])
              elsif result.key?(:strong)
                extract_text_content(result[:strong])
              elsif result.key?(:ln)
                result[:ln].to_s
              elsif result.key?(:text)
                result[:text].to_s
              else
                result.values.map { |v| extract_text_content(v) }.join
              end
            when Array
              result.map { |item| extract_text_content(item) }.join
            else
              result.to_s
            end
          end

          # Convert inline parser result to expected format
          def convert_inline_result(parsed)
            return parsed if parsed.nil?

            case parsed
            when Array
              if parsed.length == 1
                convert_inline_result(parsed.first)
              else
                parsed.map { |item| convert_inline_result(item) }
              end
            when Hash
              # Convert emphasis markers
              if parsed.key?(:emph)
                { em: convert_inline_result(parsed[:emph]) }
              elsif parsed.key?(:text)
                parsed[:text]
              elsif parsed.key?(:code)
                { code: parsed[:code] }
              else
                parsed.transform_values { |v| convert_inline_result(v) }
              end
            else
              parsed
            end
          end
        end
      end
    end
  end
end
