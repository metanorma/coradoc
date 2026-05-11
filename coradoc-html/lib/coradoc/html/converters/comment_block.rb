# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class CommentBlock < Base
        def self.to_html(comment_block, options = {})
          return '' unless comment_block
          return '' unless options[:preserve_comments]

          text = comment_block.content.to_s
          safe_text = text.gsub('--', '- -')

          doc = Nokogiri::HTML::DocumentFragment.parse('')
          comment = Nokogiri::XML::Comment.new(doc, "\n#{escape_html(safe_text)}\n")
          doc.add_child(comment)
          doc.to_html
        end

        def self.to_coradoc(element, _options = {})
          return nil unless element.comment?

          Coradoc::CoreModel::CommentBlock.new(
            content: element.text.to_s
          )
        end
      end
    end
  end
end
