# frozen_string_literal: true

module Coradoc
  module Html
    class Cleaner
      INNER_WHITESPACE_REGEX_1 = /\n stem:\[/
      INNER_WHITESPACE_REGEX_2 = /(stem:\[([^\]]|\\\])*\])\n(?=\S)/
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

      def remove_inner_whitespaces(string)
        unless string.nil?
          string.gsub!("\n stem:[", "\nstem:[")
          string.gsub!(INNER_WHITESPACE_REGEX_1, '\\1 ')
          string.gsub!(INNER_WHITESPACE_REGEX_2, '\\1')
        end
        result = +''
        string.each_line do |line|
          result << preserve_border_whitespaces(line) do
            line.gsub(/\A[ \t\r\n]+/, '').gsub(/[ \t\r\n]+\z/, '').gsub(/[ \t]{2,}/, ' ')
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
        string_start   = present_or_default(string[/\A\s*/], default_border)
        string_end     = present_or_default(string[/\s*\Z/], default_border)
        result         = yield
        string_start + result + string_end
      end

      def present_or_default(string, default)
        return default if string.nil? || string.empty?

        string
      end
    end
  end
end
