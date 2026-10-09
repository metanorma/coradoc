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

        case model
        when Coradoc::AsciiDoc::Model::Base
          model.to_adoc
        when Array
          model.map { |item| serialize(item) }.join("\n")
        when Hash
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

      # Escape delimiter characters in plain-text content so the text
      # survives a reparse (#92): `__x__`, `**x**`, `x~2~` and `` `x` ``
      # would otherwise re-enter as formatting. Runs of two or more
      # delimiters (`__`, `**`, `~~`) are dangerous anywhere; a single
      # `*`, `_` or `~` only forms a constrained pair at a
      # boundary/word transition; `^` and `` ` `` attach to words.
      def self.escape_text_delimiters(text)
        return '' if text.nil?

        text.to_s.gsub(/(?<!\\)[`*_~^]+/) do |run|
          match = Regexp.last_match
          dangerous =
            case run[0]
            when '`'
              true
            when '^'
              word_transition?(text, match)
            else
              run.length >= 2 || word_transition?(text, match)
            end
          dangerous ? run.chars.map { |c| "\\#{c}" }.join : run
        end
      end

      WHITESPACE = /\s/
      WORD_CHAR = /[[:word:]]/
      PUNCT_CHAR = /[[:punct:]]/
      private_constant :WHITESPACE, :WORD_CHAR, :PUNCT_CHAR

      # A delimiter run at [start, stop) is dangerous when it can open
      # a pair (boundary on its left, word char on its right) or close
      # one (word char on its left, boundary-or-punctuation on its
      # right — AsciiDoc lets a closing delimiter precede punctuation).
      def self.word_transition?(text, match)
        start = match.begin(0)
        stop = match.end(0)
        before = start.zero? ? nil : text[start - 1]
        after = stop >= text.length ? nil : text[stop]

        opens = boundary?(before) && word?(after)
        closes = word?(before) && (boundary?(after) || punctuation?(after))
        opens || closes
      end

      def self.boundary?(char)
        char.nil? || char.match?(WHITESPACE)
      end

      def self.word?(char)
        !char.nil? && char.match?(WORD_CHAR)
      end

      def self.punctuation?(char)
        !char.nil? && char.match?(PUNCT_CHAR)
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
