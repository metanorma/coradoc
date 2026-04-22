# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Parser
      # Single Responsibility: Detect metadata markers in AsciiDoc input
      # Stateless, no dependencies on other parser rules (Dependency Inversion)
      class MetadataDetector
        # Metadata types (MECE - Mutually Exclusive, Collectively Exhaustive)
        METADATA_TYPES = {
          block_title: /^\.[^ \n].*/,
          attribute_list: /^\[.+\]$/,
          element_id_double: /^\[\[.+\]\]$/,
          element_id_single: /^\[#.+\]$/,
          block_delimiter: /^(\*{4,}|={4,}|_{4,}|\+{4,}|-{4,}|--)/
        }.freeze

        # Scan input and return metadata markers with positions
        # @param input [String] The input text to scan
        # @param max_lines [Integer] Maximum lines to scan ahead
        # @return [Array<Hash>] Array of {type:, content:, line:, position:}
        def self.scan(input, max_lines: 20)
          lines = input.lines
          metadata = []
          found_delimiter = false

          lines.first(max_lines).each_with_index do |line, index|
            # Skip blank lines - they are not metadata
            next if line.strip.empty?

            # Stop scanning after finding a delimiter
            # (delimiter marks the start of block content)
            break if found_delimiter

            # Calculate absolute position in input
            position = lines[0...index].sum(&:length)

            # Detect each metadata type (MECE)
            METADATA_TYPES.each do |type, pattern|
              next unless line.strip&.match?(pattern)

              metadata << {
                type: type,
                content: line.strip,
                line: index,
                position: position,
                length: line.length
              }
              # Mark if we found a delimiter
              found_delimiter = true if type == :block_delimiter
              break # Each line has at most one metadata type
            end
          end

          metadata
        end

        # Detect block title (Single Responsibility)
        # @param line [String] Line to check
        # @return [Hash, nil] {text:} or nil
        def self.detect_block_title(line)
          return nil unless /^\.[^ \n]/.match?(line)

          # Extract title text (everything after '.')
          text = line.sub(/^\./, '').strip
          { text: text }
        end

        # Detect attribute list (Single Responsibility)
        # @param line [String] Line to check
        # @return [Hash, nil] {content:, attributes:} or nil
        def self.detect_attribute_list(line)
          return nil unless /^\[.+\]$/.match?(line)

          content = line.strip
          # Parse basic attribute structure
          inner = content[1...-1] # Remove [ and ]

          # Simple attribute parsing (positional)
          attributes = inner.split(',').map(&:strip)

          {
            content: content,
            attributes: attributes
          }
        end

        # Detect element ID (Single Responsibility)
        # @param line [String] Line to check
        # @return [Hash, nil] {id:, style:} or nil
        def self.detect_element_id(line)
          # Double bracket style: [[id]]
          return { id: ::Regexp.last_match(1), style: :double } if line =~ /^\[\[(.+)\]\]$/

          # Single bracket style: [#id]
          return { id: ::Regexp.last_match(1), style: :single } if line =~ /^\[#(.+)\]$/

          nil
        end

        # Detect block delimiter (Single Responsibility)
        # @param line [String] Line to check
        # @return [Hash, nil] {char:, count:, type:} or nil
        def self.detect_block_delimiter(line)
          return nil unless line =~ /^(\*{4,}|={4,}|_{4,}|\+{4,}|-{4,}|--)$/

          delimiter = ::Regexp.last_match(1)
          char = delimiter[0]
          count = delimiter.length

          # Map to block type
          type = case char
                 when '*' then :sidebar
                 when '=' then :example
                 when '_' then :quote
                 when '+' then :pass
                 when '-' then count == 2 ? :open : :source
                 end

          {
            char: char,
            count: count,
            type: type,
            delimiter: delimiter
          }
        end

        # Analyze block structure from metadata (MECE patterns)
        # @param metadata [Array<Hash>] Metadata from scan()
        # @return [Hash, nil] {pattern:, title:, attributes:, delimiter:} or nil
        def self.analyze_block_structure(metadata)
          return nil if metadata.empty?

          # Find block delimiter (required for block)
          delim_meta = metadata.find { |m| m[:type] == :block_delimiter }
          return nil unless delim_meta

          # Find title and attributes
          title_meta = metadata.find { |m| m[:type] == :block_title }
          attr_meta = metadata.find { |m| m[:type] == :attribute_list }

          # Determine MECE pattern
          pattern = if title_meta && attr_meta
                      :title_attr_delim
                    elsif title_meta
                      :title_delim
                    elsif attr_meta
                      :attr_delim
                    else
                      :plain_delim
                    end

          {
            pattern: pattern,
            title: title_meta ? detect_block_title(title_meta[:content]) : nil,
            attributes: attr_meta ? detect_attribute_list(attr_meta[:content]) : nil,
            delimiter: detect_block_delimiter(delim_meta[:content]),
            delimiter_line: delim_meta[:line]
          }
        end
      end
    end
  end
end
