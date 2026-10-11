# frozen_string_literal: true

module Coradoc
  module Html
    class Cleaner
      INNER_WHITESPACE_REGEX_1 = /\n stem:\[/
      NEWLINES_REGEX = /\n{3,}/
      LEADING_NEWLINE_REGEX = /\A\n+/
      WHITESPACE_REGEX = /[ \t\r\n]+/
      TRAILING_WHITESPACE_REGEX = /[ \t\r\n]+\z/

      def tidy(string)
        return string.transform_values { |i| tidy(i) } if string.is_a? Hash

        result = HtmlConverter.track_time 'Removing inner whitespace' do
          remove_inner_whitespaces(String.new(string))
        end
        result = HtmlConverter.track_time 'Removing newlines' do
          remove_newlines(result)
        end
        result = HtmlConverter.track_time 'Removing leading newlines' do
          remove_leading_newlines(result)
        end
        result = HtmlConverter.track_time 'Cleaning tag borders' do
          clean_tag_borders(result)
        end
        result = HtmlConverter.track_time 'Cleaning punctuation characters' do
          clean_punctuation_characters(result)
        end
        result = remove_block_leading_newlines(result)
        result = remove_section_attribute_newlines(result)
      end

      def remove_block_leading_newlines(string)
        string.gsub("]\n****\n\n", "]\n****\n")
      end

      def remove_section_attribute_newlines(string)
        string.gsub("]\n\n==", "]\n==")
      end

      def remove_newlines(string)
        string.gsub(NEWLINES_REGEX, "\n\n")
      end

      def remove_leading_newlines(string)
        string.gsub(LEADING_NEWLINE_REGEX, '')
      end

      # Drop the newline joining a stem macro's closing bracket to the
      # following text. A linear character scan instead of a regex —
      # CodeQL rb/polynomial-redos flags even nested-star and
      # possessive-quantifier forms, so no quantifiers at all.
      def remove_stem_macro_newlines(string)
        pos = 0
        while (start = string.index('stem:[', pos))
          close = closing_bracket_after(string, start + 6)
          break if close.nil?

          next unless string[close + 1] == "\n" && string[close + 2]&.match?(/\S/)

          string.slice! close + 1, 1
          pos = close + 1
        end
        string
      end

      # Index of the first unescaped ']' at or after +from+.
      def closing_bracket_after(string, from)
        i = from
        while i < string.length
          char = string[i]
          return i if char == ']'

          i += char == '\\' ? 2 : 1
        end
        nil
      end

      def remove_inner_whitespaces(string)
        unless string.nil?
          string.gsub!("\n stem:[", "\nstem:[")
          string.gsub!(INNER_WHITESPACE_REGEX_1, '\\1 ')
          remove_stem_macro_newlines(string)
        end
        result = +''
        string.each_line do |line|
          result << preserve_border_whitespaces(line) do
            line.strip.gsub(/[ \t]{2,}/, ' ')
          end
        end
        result
      end

      def clean_tag_borders(string)
        result = string.gsub(/\s?~{2,}.*?~{2,}\s?/) do |match|
          preserve_border_whitespaces(
            match,
            default_border: Html.input_config.tag_border
          ) do
            match.strip.sub('~~ ', '~~').sub(' ~~', '~~')
          end
        end

        result.gsub(/\s?\[.*?\]\s?/) do |match|
          preserve_border_whitespaces(match) do
            match.strip.sub('[ ', '[').sub(' ]', ']')
          end
        end
      end

      def clean_punctuation_characters(string)
        string.gsub(/(\*\*|~~|__)\s([.!?'"])/, '\\1\\2')
      end

      def preprocess_word_html(string)
        clean_headings(scrub_whitespace(string.dup))
      end

      def scrub_whitespace(string)
        string.gsub!(/&nbsp;|&#xA0;| /i, '&#xA0;')
        string = Coradoc.strip_unicode(string)
        string.gsub!(/( +)$/, ' ')
        string.gsub!("\n\n\n\n", "\n\n")
        string
      end

      def clean_headings(string)
        string.gsub!(%r{<h([1-9])[^>]*></h\1>}, ' ')
        string.gsub!(
          %r{<h([1-9])[^>]* style="vertical-align: super;[^>]*>(.+?)</h\1>},
          '<sup>\\2</sup>'
        )
        string
      end

      private

      def preserve_border_whitespaces(string, options = {})
        return string if /\A\s*\Z/.match?(string)

        default_border = options.fetch(:default_border, '')
        default_border = '' if /[\[(\])]/.match?(string)
        string_start   = present_or_default(leading_whitespace(string), default_border)
        string_end     = present_or_default(trailing_whitespace(string), default_border)
        result         = yield
        string_start + result + string_end
      end

      # Leading/trailing whitespace runs via a linear scan — the
      # /\s*\Z/ and /\A\s*/ forms are modeled as polynomial-redos
      # risks by CodeQL.
      def leading_whitespace(string)
        i = 0
        i += 1 while i < string.length && string[i].match?(/\s/)
        string[0, i]
      end

      def trailing_whitespace(string)
        i = string.length
        i -= 1 while i.positive? && string[i - 1].match?(/\s/)
        string[i..]
      end

      def present_or_default(string, default)
        return default if string.nil? || string.empty?

        string
      end
    end
  end
end
