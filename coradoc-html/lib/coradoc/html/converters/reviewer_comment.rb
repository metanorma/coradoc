# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class ReviewerComment < Base
        def self.to_html(comment, _options = {})
          return '' unless comment

          attrs = { class: 'reviewer-note' }
          attrs[:id] = comment.id if comment.id

          children = []

          children << NodeBuilder.build(:span, 'Reviewer Note', class: 'reviewer-note-label')

          reviewer_info = extract_reviewer_info(comment.metadata)
          children << NodeBuilder.build(:fragment, reviewer_info) unless reviewer_info.empty?

          content = process_content(comment.content)
          children << NodeBuilder.build(:div, content, class: 'reviewer-note-content')

          NodeBuilder.build(:div, children, **attrs).to_html
        end

        def self.process_content(content)
          return '' if content.nil?

          if content.is_a?(String)
            escape_html(content)
          elsif content.is_a?(Array)
            content.map { |item| convert_item(item) }.join("\n")
          else
            convert_item(content)
          end
        end

        def self.convert_item(item)
          case item
          when String
            escape_html(item)
          else
            convert_content_to_html(item)
          end
        end

        def self.extract_reviewer_info(metadata)
          return '' if metadata.nil?

          reviewer = metadata[:reviewer]
          return '' unless reviewer

          span = NodeBuilder.build(:span, "reviewer=#{escape_html(reviewer)}", class: 'metadata-item')
          NodeBuilder.build(:div, span, class: 'reviewer-note-metadata').to_html
        end
      end
    end
  end
end
