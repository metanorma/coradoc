# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Parser
      # Single Responsibility: Assemble block AST from metadata hints
      # Takes metadata analysis and input text, returns proper AST structure
      class BlockAssembler
        # Main entry point: assemble block AST from input and metadata.
        #
        # The result hash always includes :delimiter and :lines. :title and
        # :attribute_list are included only when present in the metadata.
        # The previous 4-arm `case pattern` switch collapsed into this single
        # method once it became clear the only difference between arms was
        # which optional keys appeared in the result hash.
        #
        # @param input [String] The input text to parse
        # @param metadata [Hash] Analysis from MetadataDetector
        # @return [Hash, nil] AST hash, or nil if metadata is nil
        def self.assemble(input, metadata)
          return nil unless metadata

          lines = input.lines
          delimiter_line = metadata[:delimiter_line]
          delimiter = metadata[:delimiter][:delimiter]

          result = {
            delimiter: delimiter,
            lines: extract_block_lines(lines, delimiter_line, delimiter)
          }
          result[:title] = metadata[:title][:text] if metadata[:title]
          result[:attribute_list] = parse_attribute_list(metadata[:attributes]) if metadata[:attributes]
          result
        end

        # Helper: Extract content between delimiters
        # @param lines [Array<String>] All lines of input
        # @param delimiter_line [Integer] Line number of opening delimiter
        # @param delimiter [String] The delimiter string (e.g., "****")
        # @return [Array<Hash>] Array of {:text => "...", :line_break => "\n"}
        def self.extract_block_lines(lines, delimiter_line, delimiter)
          block_lines = []

          # Start from line after opening delimiter
          i = delimiter_line + 1

          # Collect lines until closing delimiter
          while i < lines.length
            line = lines[i]

            # Check if this is the closing delimiter
            break if line.strip == delimiter

            stripped = line.strip
            if nested_delimiter?(stripped) && stripped != delimiter
              nested_delimiter = stripped
              nested_lines = extract_block_lines(lines, i, nested_delimiter)

              block_lines << { block: { delimiter: nested_delimiter, lines: nested_lines } }

              i += nested_lines.length + 1
            elsif line.strip.empty?
              # Handle empty lines vs content lines
              block_lines << { line_break: "\n" }
            else
              # Remove trailing newline for processing
              text = line.chomp
              block_lines << { text: text, line_break: "\n" }
            end

            i += 1
          end

          block_lines
        end

        def self.nested_delimiter?(str)
          return false if str.length < 2

          char = str[0]
          return false unless ['-', '*', '=', '_', '+'].include?(char)
          return false unless str.chars.all? { |c| c == char }

          (char == '-' && str.length == 2) || str.length >= 4
        end

        # Parse attribute list to match expected AST structure
        # @param attr_meta [Hash] Attribute metadata from detector
        # @return [Hash] Properly formatted attribute_list hash
        def self.parse_attribute_list(attr_meta)
          return nil unless attr_meta

          # Get the raw content (without brackets)
          content = attr_meta[:content]
          attr_content = content[1...-1] # Remove [ and ]

          # Get attributes array from metadata
          attributes = attr_meta[:attributes]

          # Build attribute_array in expected format
          attribute_array = attributes.map do |attr|
            # Check if it's a named attribute (key=value)
            if attr.include?('=')
              key, value = attr.split('=', 2)
              { named: { named_key: key.strip, named_value: value.strip } }
            else
              # Positional attribute
              { positional: attr.strip }
            end
          end

          {
            attr_content: attr_content,
            attribute_array: attribute_array
          }
        end
      end
    end
  end
end
