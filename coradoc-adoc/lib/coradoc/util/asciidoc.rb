# frozen_string_literal: true

module Coradoc
  module Util
    # AsciiDoc-specific utility functions
    module AsciiDoc
      # Serialize a Coradoc model to AsciiDoc string
      #
      # @param model [Object] The model to serialize
      # @return [String] The AsciiDoc representation
      #
      # @example Serialize a document
      #   serialize(document)  # => "= Title\n\nContent"
      #
      def self.serialize(model)
        return '' if model.nil?
        return model if model.is_a?(String)

        if model.respond_to?(:to_adoc)
          model.to_adoc
        elsif model.is_a?(Array)
          model.map { |item| serialize(item) }.join("\n")
        elsif model.is_a?(Hash)
          model.map { |k, v| "#{k}: #{serialize(v)}" }.join("\n")
        else
          model.to_s
        end
      end

      # Escape special AsciiDoc characters in content
      #
      # @param content [String] The content to escape
      # @param escape_chars [Array<String>] Characters to escape (e.g., ["*", "_", "#"])
      # @return [String] The escaped content
      #
      # @example Escape asterisks for bold text
      #   escape_characters("2 * 3 = 6", escape_chars: ["*"])
      #   # => "2 \\* 3 = 6"
      #
      def self.escape_characters(content, escape_chars: [])
        return '' if content.nil?
        return content if escape_chars.empty?

        result = content.to_s
        escape_chars.each do |char|
          # Escape the character with backslash, but only if not already escaped
          result = result.gsub(/(?<!\\)#{Regexp.escape(char)}/, "\\#{char}")
        end
        result
      end

      # Unescape AsciiDoc characters in content
      #
      # @param content [String] The content to unescape
      # @param escape_chars [Array<String>] Characters to unescape
      # @return [String] The unescaped content
      #
      def self.unescape_characters(content, escape_chars: [])
        return '' if content.nil?
        return content if escape_chars.empty?

        result = content.to_s
        escape_chars.each do |char|
          result = result.gsub("\\#{char}", char)
        end
        result
      end
    end
  end
end
