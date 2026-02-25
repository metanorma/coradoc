# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for CoreModel::Block with element_type "comment"
      class CommentBlock < Base
        # Convert CoreModel::Block (comment) to HTML comment
        def self.to_html(comment_block, options = {})
          return '' unless comment_block

          # Check if comments should be preserved
          return '' unless options[:preserve_comments]

          # Get comment text (CoreModel::Block has content attribute)
          text = comment_block.content.to_s

          # HTML comments cannot contain --
          # Replace -- with - - to avoid breaking the comment
          safe_text = text.gsub('--', '- -')

          # Preserve newlines in comment block
          # Multi-line comment blocks should preserve their internal newlines
          "<!--\n#{escape_html(safe_text)}\n-->"
        end

        # Convert HTML comment to CoreModel::Block (comment)
        def self.to_coradoc(element, _options = {})
          return nil unless element.comment?

          # Extract comment text
          text = element.text.to_s

          Coradoc::CoreModel::Block.new(
            element_type: 'comment',
            content: text
          )
        end
      end
    end
  end
end
