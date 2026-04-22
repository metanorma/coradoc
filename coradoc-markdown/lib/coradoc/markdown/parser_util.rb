# frozen_string_literal: true

require 'strscan'

module Coradoc
  module Markdown
    # Shared parser utilities for Markdown processing
    module ParserUtil
      # Parser for IAL (Inline Attribute List) syntax
      #
      # IAL syntax: {:.class #id key="value"}
      # Supports:
      # - Classes: .classname or .-classname
      # - IDs: #idname
      # - Key-value pairs: key="value", key='value', or key=value
      #
      module IalParser
        # Tokenize an IAL string into its components
        # @param content [String] The IAL content (without braces)
        # @return [Array<Hash>] Array of tokens with :type and :value
        def self.tokenize(content)
          tokens = []
          scanner = StringScanner.new(content.to_s)

          until scanner.eos?
            scanner.skip(/\s+/)
            break if scanner.eos?

            if scanner.scan(/\.(-?\w[\w-]*)/)
              tokens << { type: :class, value: scanner[1] }
            elsif scanner.scan(/#(\w[\w-]*)/)
              tokens << { type: :id, value: scanner[1] }
            elsif scanner.scan(/(\w[\w-]*)\s*=\s*/)
              key = scanner[1]
              value = extract_quoted_value(scanner, handle_escapes: true)
              tokens << { type: :attribute, key: key, value: value }
            elsif scanner.scan(/\S+/)
              # Skip unknown tokens
            end
          end

          tokens
        end

        # Parse IAL content into a hash
        # @param content [String] The IAL content
        # @return [Hash] Parsed result with :id, :classes, :attributes keys
        def self.parse_to_hash(content)
          result = { id: nil, classes: [], attributes: {} }
          return result if content.nil? || content.empty?

          tokens = tokenize(content)
          tokens.each do |token|
            case token[:type]
            when :class
              result[:classes] << token[:value]
            when :id
              result[:id] = token[:value]
            when :attribute
              result[:attributes][token[:key]] = token[:value]
            end
          end

          result
        end

        # Extract a quoted value from the scanner
        # @param scanner [StringScanner]
        # @param handle_escapes [Boolean] Whether to unescape \\" and \\'
        # @return [String] The extracted value
        def self.extract_quoted_value(scanner, handle_escapes: false)
          if scanner.scan(/"([^"\\]*(?:\\.[^"\\]*)*)"/)
            value = scanner[1]
            value = value.gsub(/\\"/, '"') if handle_escapes
            value
          elsif scanner.scan(/'([^'\\]*(?:\\.[^'\\]*)*)'/)
            value = scanner[1]
            value = value.gsub(/\\'/, "'") if handle_escapes
            value
          elsif scanner.scan(/(\S+)/)
            scanner[1]
          else
            ''
          end
        end
        private_class_method :extract_quoted_value
      end
    end
  end
end
