# frozen_string_literal: true

require 'parslet'
require_relative 'parser_util'

module Coradoc
  module Markdown
    # Transformer converts Parslet AST into Markdown Document Model objects.
    #
    # This transformer takes the raw output from the BlockParser/InlineParser
    # and converts it into semantic model objects (Heading, Paragraph, etc.)
    #
    class Transformer < Parslet::Transform
      # ATX Heading: # Heading
      rule(heading: simple(:heading), text: simple(:text)) do
        Heading.new(level: heading.to_s.length, text: text.to_s.strip)
      end

      # ATX Heading without text (just #)
      rule(heading: simple(:heading)) do
        Heading.new(level: heading.to_s.length, text: '')
      end

      # Thematic break (horizontal rule)
      rule(hr: simple(:hr)) do
        HorizontalRule.new(style: '---')
      end

      # Code block (fenced or indented)
      rule(code_block: sequence(:lines)) do
        code = lines.map { |l| l.is_a?(Hash) ? (l[:ln] || '') : l.to_s }.join("\n")
        CodeBlock.new(code: "#{code.rstrip}\n")
      end

      rule(code_block: simple(:line)) do
        code = line.is_a?(Hash) ? (line[:ln] || '') : line.to_s
        CodeBlock.new(code: "#{code}\n")
      end

      # Block quote
      rule(block_quote: subtree(:content)) do
        # Recursively transform block quote content
        transformed = content.is_a?(Array) ? content.map { |c| transform_element(c) } : [transform_element(content)]
        text = transformed.map { |c| c.respond_to?(:text) ? c.text : c.to_s }.join("\n")
        Blockquote.new(content: text)
      end

      # Paragraph
      rule(p: { ln: simple(:text) }) do
        Paragraph.new(text: text.to_s)
      end

      rule(p: sequence(:lines)) do
        text = lines.map { |l| l.is_a?(Hash) ? (l[:ln] || '') : l.to_s }.join("\n")
        Paragraph.new(text: text)
      end

      # Setext heading (underline style)
      rule(text: subtree(:text_content), heading: simple(:heading)) do
        # Extract text from the text_content
        lines = text_content.is_a?(Array) ? text_content : [text_content]
        text = lines.map do |l|
          case l
          when Hash then l[:ln] || ''
          else l.to_s
          end
        end.join("\n")

        level = heading.to_s.start_with?('=') ? 1 : 2
        Heading.new(level: level, text: text.strip)
      end

      # Inline elements
      rule(text: simple(:text)) do
        Text.new(content: text.to_s)
      end

      rule(code: simple(:code)) do
        Code.new(text: code.to_s)
      end

      rule(emph: subtree(:content)) do
        text = extract_text(content)
        Emphasis.new(text: text)
      end

      rule(strong: subtree(:content)) do
        text = extract_text(content)
        Strong.new(text: text)
      end

      # ===== KRAMDOWN EXTENSIONS =====

      # IAL (Inline Attribute List): {:.class #id key="value"}
      rule(ial: simple(:ial_content)) do
        AttributeList.parse("{:#{ial_content}}")
      end

      # ALD (Attribute List Definition): {:name: #id .class}
      rule(ald_name: simple(:name), ial: simple(:ial_content)) do
        AttributeList.new(
          name: name.to_s,
          **parse_ial_content(ial_content.to_s)
        )
      end

      # Extension (self-closing): {::toc /} or {::options key="value" /}
      rule(extension: {
             ext_name: simple(:name),
             ext_options: simple(:opts)
           }) do
        Extension.new(
          name: name.to_s,
          options: parse_extension_options(opts.to_s)
        )
      end

      rule(extension: {
             ext_name: simple(:name),
             ext_options: simple(:opts),
             ext_body: simple(:body)
           }) do
        Extension.new(
          name: name.to_s,
          options: parse_extension_options(opts.to_s),
          content: body.to_s
        )
      end

      # Block math: $$...$$
      rule(math_content: simple(:content)) do
        Math.block(content.to_s.strip)
      end

      # Fallback for unmatched elements
      rule(simple(:value)) do
        Text.new(content: value.to_s) if value.respond_to?(:to_s)
      end

      class << self
        # ALD storage - maps name to AttributeList
        attr_accessor :ald_registry

        # Transform AST into a Document model
        #
        # @param ast [Array] The parsed AST from BlockParser
        # @return [Coradoc::Markdown::Document] The document model
        def transform_document(ast)
          @ald_registry = {}
          blocks = Array(ast).map { |element| transform_element(element) }.compact
          Document.new(blocks: blocks)
        end

        # Transform a single element
        def transform_element(element)
          return nil if element.nil?

          case element
          when Hash
            # Handle ALD first (register it)
            if element.key?(:ald_name)
              register_ald(element)
              return nil
            end

            # Handle IAL on its own line (reference or standalone)
            if element.key?(:ial) && !element.key?(:p) && !element.key?(:heading)
              ial = parse_ial_element(element[:ial])
              # Check if it's a reference to an ALD
              return @ald_registry[ial] if ial.is_a?(String) && @ald_registry.key?(ial)

              return ial
            end

            # Handle extension
            return transform_extension(element[:extension]) if element.key?(:extension)

            # Handle extension (direct key)
            return transform_extension(element) if element.key?(:ext_name)

            # Handle math
            return Math.block(extract_text(element[:math_content])) if element.key?(:math_content)

            # Handle footnote reference (inline)
            return FootnoteReference.new(id: element[:fn_ref].to_s) if element.key?(:fn_ref)

            # Try to transform using rules
            transformed = try_transform(element)
            return transformed if transformed

            # If no rule matches, try to extract text
            if element.key?(:ln)
              Paragraph.new(text: element[:ln].to_s)
            elsif element.key?(:text)
              Text.new(content: element[:text].to_s)
            end
          when Array
            # Transform each item
            element.map { |e| transform_element(e) }.compact
          when Parslet::Slice
            Text.new(content: element.to_s)
          else
            Text.new(content: element.to_s)
          end
        end

        # Register an ALD (Attribute List Definition)
        def register_ald(element)
          name = element[:ald_name].to_s
          ial_content = element[:ial].to_s
          attrs = parse_ial_content(ial_content)
          @ald_registry[name] = AttributeList.new(name: name, **attrs)
        end

        # Transform extension element
        def transform_extension(element)
          name = element[:ext_name].to_s
          opts = element[:ext_options]
          # Handle empty array from parser
          options = if opts.is_a?(Array) && opts.empty?
                      {}
                    elsif opts
                      parse_extension_options(opts.to_s)
                    else
                      {}
                    end
          body = element[:ext_body]

          Extension.new(
            name: name,
            options: options,
            content: body&.to_s
          )
        end

        # Try to transform using the defined rules
        def try_transform(element)
          return nil unless element.is_a?(Hash)

          # Check for known patterns and transform them
          if element.key?(:heading)
            level = element[:heading].to_s.length
            text = element[:text] ? element[:text].to_s.strip : ''
            heading = Heading.new(level: level, text: text)
            # Apply IAL if present
            apply_ial_to_element(heading, element[:ial]) if element.key?(:ial)
            return heading
          end

          return HorizontalRule.new(style: '---') if element.key?(:hr)

          # Fenced code block with language info
          if element.key?(:info) && element.key?(:code_block)
            language = element[:info].to_s.strip
            code = extract_code(element[:code_block])
            code_block = CodeBlock.new(language: language, code: code)
            apply_ial_to_element(code_block, element[:ial]) if element.key?(:ial)
            return code_block
          end

          if element.key?(:code_block)
            code = extract_code(element[:code_block])
            code_block = CodeBlock.new(code: code)
            apply_ial_to_element(code_block, element[:ial]) if element.key?(:ial)
            return code_block
          end

          if element.key?(:block_quote)
            content = element[:block_quote]
            transformed = content.is_a?(Array) ? content.map { |c| transform_element(c) } : [transform_element(content)]
            text = transformed.compact.map { |c| c.respond_to?(:text) ? c.text : c.to_s }.join("\n")
            blockquote = Blockquote.new(content: text)
            apply_ial_to_element(blockquote, element[:ial]) if element.key?(:ial)
            return blockquote
          end

          if element.key?(:p)
            text = extract_text_from_p(element[:p])
            paragraph = Paragraph.new(text: text)
            apply_ial_to_element(paragraph, element[:ial]) if element.key?(:ial)
            return paragraph
          end

          # Definition list
          return transform_definition_list(element[:dl]) if element.key?(:dl)

          # Footnote definition
          if element.key?(:fn_id)
            content = if element[:fn_content_continued]
                        lines = [element[:fn_content]]
                        lines += Array(element[:fn_content_continued])
                        lines.map { |l| extract_text(l) }.join("\n")
                      else
                        extract_text(element[:fn_content])
                      end
            return Footnote.new(id: element[:fn_id].to_s, content: content.strip)
          end

          # Abbreviation definition
          if element.key?(:abbr_term)
            return Abbreviation.new(
              term: element[:abbr_term].to_s,
              definition: element[:abbr_def].to_s.strip
            )
          end

          nil
        end

        # Transform definition list
        def transform_definition_list(dl_content)
          # The parser outputs term and definition as separate items
          # We need to group them: [{:def_term=>...}, {:def_content=>...}, ...]
          items = []
          current_term = nil
          current_definitions = []

          Array(dl_content).each do |item|
            next unless item.is_a?(Hash)

            if item.key?(:def_term)
              # Save previous term if exists
              if current_term
                items << DefinitionTerm.new(
                  text: current_term.strip,
                  definitions: current_definitions
                )
              end

              # Start new term
              current_term = extract_text(item[:def_term])
              current_definitions = []
            elsif item.key?(:def_content)
              # Add definition to current term
              content = extract_text(item[:def_content])
              current_definitions << DefinitionItem.new(content: content.strip)
            end
          end

          # Don't forget the last term
          if current_term
            items << DefinitionTerm.new(
              text: current_term.strip,
              definitions: current_definitions
            )
          end

          DefinitionList.new(items: items)
        end

        # Apply IAL attributes to an element
        def apply_ial_to_element(element, ial_content)
          attrs = parse_ial_content(ial_content.to_s)
          element.id = attrs[:id] if attrs[:id]
          element.classes = attrs[:classes] if attrs[:classes]
          element.attributes = attrs[:attributes] if attrs[:attributes]
          element
        end

        # Parse IAL content string into components
        # Delegates to shared IalParser for consistent parsing
        def parse_ial_content(content)
          ParserUtil::IalParser.parse_to_hash(content)
        end

        # Parse extension options string into hash
        def parse_extension_options(content)
          return {} if content.nil? || content.empty?

          result = {}
          scanner = StringScanner.new(content.strip)

          until scanner.eos?
            scanner.skip(/\s+/)
            break if scanner.eos?

            if scanner.scan(/(\w[\w-]*)\s*=\s*/)
              key = scanner[1]
              value = if scanner.scan(/"([^"\\]*)"/)
                        scanner[1]
                      elsif scanner.scan(/'([^'\\]*)'/)
                        scanner[1]
                      elsif scanner.scan(/(\S+)/)
                        scanner[1]
                      else
                        ''
                      end
              result[key] = value
            else
              # Skip unrecognized character to avoid infinite loop
              scanner.scan(/./)
            end
          end

          result
        end

        # Parse IAL element (can be a reference or full IAL)
        def parse_ial_element(ial_content)
          content = ial_content.to_s.strip
          # Check if it's just a name reference (no . or #)
          if content =~ /\A\w+\z/ && @ald_registry.key?(content)
            @ald_registry[content]
          else
            attrs = parse_ial_content(content)
            AttributeList.new(
              id: attrs[:id],
              classes: attrs[:classes],
              attributes: attrs[:attributes]
            )
          end
        end

        # Extract text from paragraph structure
        def extract_text_from_p(p)
          case p
          when Hash
            p[:ln].to_s
          when Array
            p.map { |l| l.is_a?(Hash) ? l[:ln].to_s : l.to_s }.join("\n")
          else
            p.to_s
          end
        end

        # Extract code from code_block structure
        def extract_code(code_block)
          case code_block
          when Array
            code_block.map { |l| l.is_a?(Hash) ? l[:ln].to_s : l.to_s }.join("\n")
          when Hash
            code_block[:ln].to_s
          else
            code_block.to_s
          end
        end

        # Extract text content from nested structures
        def extract_text(content)
          case content
          when Array
            content.map { |c| extract_text(c) }.join
          when Hash
            if content.key?(:text)
              content[:text].to_s
            elsif content.key?(:ln)
              content[:ln].to_s
            else
              content.values.map { |v| extract_text(v) }.join
            end
          when Parslet::Slice
            content.to_s
          else
            content.to_s
          end
        end
      end
    end
  end
end
