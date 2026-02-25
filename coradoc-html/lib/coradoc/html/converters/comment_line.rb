# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class CommentLine < Base
        # Convert CoreModel to HTML comment
        def self.to_html(comment, options = {})
          return '' unless comment

          # Check if comments should be preserved
          return '' unless options[:preserve_comments]

          # Get comment text - check for content or text attribute
          text = if comment.respond_to?(:content) && comment.content
                   comment.content
                 elsif comment.respond_to?(:text) && comment.text
                   comment.text
                 else
                   ''
                 end

          text = text.to_s

          # HTML comments cannot contain --
          # Replace -- with - - to avoid breaking the comment
          safe_text = text.gsub('--', '- -')

          # Preserve newlines in comment text
          # Empty comments (just "//") should become newlines in HTML comments
          if safe_text.strip.empty?
            "<!--\n-->"
          else
            "<!-- #{escape_html(safe_text)} -->"
          end
        end

        # Convert HTML comment to CoreModel
        def self.to_coradoc(element, _options = {})
          return nil unless element.comment?

          # Extract comment text
          text = element.text.to_s.strip

          # For now, return an InlineElement with special format_type for comment
          Coradoc::CoreModel::InlineElement.new(
            format_type: 'comment',
            content: text
          )
        end
      end
    end
  end
end
