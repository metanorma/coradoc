# frozen_string_literal: true

require 'strscan'

module Coradoc
  module Markdown
    module Bindings
      # Readers for the raw captures of the Markdown block grammar: the
      # small, stateless text and attribute-list steps the binding hooks
      # (and the residual Transformer) share.
      module Captures
        module_function

        # ATX heading: level is the count of leading '#' chars.
        # Setext heading: level is 1 for '=' underline, 2 for '-' underline.
        def heading_level(heading)
          s = heading.to_s
          return s.length if s.start_with?('#')
          return 1 if s.start_with?('=')
          return 2 if s.start_with?('-')

          s.length
        end

        # Normalize the various shapes a list-item node can take:
        #   Hash {p: ...}     -> [{p: ...}]
        #   Hash {ul: ...}    -> [{ul: ...}]  (nested list, no text)
        #   Array [...]       -> [...] (mixed paragraph + nested list nodes)
        #   String / Slice    -> [s]
        def normalize_list_item_nodes(item)
          item.is_a?(Array) ? item : [item]
        end

        def extract_row_cells(row)
          Array(row).map do |cell|
            next cell.to_s.strip unless cell.is_a?(Hash)

            cell[:cell].to_s.strip
          end
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

        # Extract text from paragraph structure
        def extract_text_from_p(para)
          case para
          when Hash
            para[:ln].to_s
          when Array
            para.map { |l| l.is_a?(Hash) ? l[:ln].to_s : l.to_s }.join("\n")
          else
            para.to_s
          end
        end

        # Recursively flatten any inline subtree (arrays, nested
        # strong/emph hashes, code spans, Parsanol slices) to its
        # literal text. Inner style markers survive as characters so
        # the round trip stays stable.
        def flatten_inline_text(subtree)
          case subtree
          when Array
            subtree.map { |n| flatten_inline_text(n) }.join
          when Hash
            if subtree.key?(:text)
              subtree[:text].to_s
            elsif subtree.key?(:code)
              "`#{subtree[:code]}`"
            else
              subtree.values.map { |v| flatten_inline_text(v) }.join
            end
          else
            subtree.to_s
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
          else
            content.to_s
          end
        end
      end
    end
  end
end
