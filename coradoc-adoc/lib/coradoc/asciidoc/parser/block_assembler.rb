# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Parser
      # Single Responsibility: Assemble block AST from metadata hints
      # Takes metadata analysis and input text, returns proper AST structure
      class BlockAssembler
        # Main entry point: assemble block AST from input and metadata
        # @param input [String] The input text to parse
        # @param metadata_analysis [Hash] Analysis from MetadataDetector
        # @return [Hash] AST hash {:block => {...}}
        def self.assemble(input, metadata_analysis)
          return nil unless metadata_analysis

          pattern = metadata_analysis[:pattern]

          # Delegate to pattern-specific methods (Open/Closed Principle)
          case pattern
          when :title_attr_delim
            assemble_title_attr_delim(input, metadata_analysis)
          when :title_delim
            assemble_title_delim(input, metadata_analysis)
          when :attr_delim
            assemble_attr_delim(input, metadata_analysis)
          when :plain_delim
            assemble_plain_delim(input, metadata_analysis)
          end
        end

        # Handle: Title + Attribute + Delimiter pattern
        # @param input [String] The input text
        # @param metadata [Hash] Metadata analysis
        # @return [Hash] Complete block hash
        def self.assemble_title_attr_delim(input, metadata)
          lines = input.lines
          delimiter_line = metadata[:delimiter_line]
          delimiter = metadata[:delimiter][:delimiter]

          # Extract components
          title_text = metadata[:title][:text]
          attr_list = parse_attribute_list(metadata[:attributes])

          # Extract block content
          block_lines = extract_block_lines(lines, delimiter_line, delimiter)

          {
            title: title_text,
            attribute_list: attr_list,
            delimiter: delimiter,
            lines: block_lines
          }
        end

        # Handle: Title + Delimiter pattern (no attributes)
        # @param input [String] The input text
        # @param metadata [Hash] Metadata analysis
        # @return [Hash] Block hash without attributes
        def self.assemble_title_delim(input, metadata)
          lines = input.lines
          delimiter_line = metadata[:delimiter_line]
          delimiter = metadata[:delimiter][:delimiter]

          # Extract components
          title_text = metadata[:title][:text]

          # Extract block content
          block_lines = extract_block_lines(lines, delimiter_line, delimiter)

          {
            title: title_text,
            delimiter: delimiter,
            lines: block_lines
          }
        end

        # Handle: Attribute + Delimiter pattern (no title)
        # @param input [String] The input text
        # @param metadata [Hash] Metadata analysis
        # @return [Hash] Block hash without title
        def self.assemble_attr_delim(input, metadata)
          lines = input.lines
          delimiter_line = metadata[:delimiter_line]
          delimiter = metadata[:delimiter][:delimiter]

          # Extract components
          attr_list = parse_attribute_list(metadata[:attributes])

          # Extract block content
          block_lines = extract_block_lines(lines, delimiter_line, delimiter)

          {
            attribute_list: attr_list,
            delimiter: delimiter,
            lines: block_lines
          }
        end

        # Handle: Just Delimiter pattern
        # @param input [String] The input text
        # @param metadata [Hash] Metadata analysis
        # @return [Hash] Minimal block hash
        def self.assemble_plain_delim(input, metadata)
          lines = input.lines
          delimiter_line = metadata[:delimiter_line]
          delimiter = metadata[:delimiter][:delimiter]

          # Extract block content
          block_lines = extract_block_lines(lines, delimiter_line, delimiter)

          {
            delimiter: delimiter,
            lines: block_lines
          }
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

            # Handle empty lines vs content lines
            if line.strip.empty?
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
