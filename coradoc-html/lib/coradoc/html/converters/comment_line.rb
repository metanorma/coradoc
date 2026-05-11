# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class CommentLine < Base
        def self.to_html(comment, options = {})
          return '' unless comment
          return '' unless options[:preserve_comments]

          text = if comment.content
                   comment.content
                 elsif comment.text
                   comment.text
                 else
                   ''
                 end

          text = text.to_s
          safe_text = text.gsub('--', '- -')

          doc = Nokogiri::HTML::DocumentFragment.parse('')
          comment_text = safe_text.strip.empty? ? '' : " #{escape_html(safe_text)} "
          comment_node = Nokogiri::XML::Comment.new(doc, comment_text)
          doc.add_child(comment_node)
          doc.to_html
        end

        def self.to_coradoc(element, _options = {})
          return nil unless element.comment?

          Coradoc::CoreModel::InlineElement.new(
            format_type: 'comment',
            content: element.text.to_s.strip
          )
        end
      end
    end
  end
end
