# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for CoreModel::AnnotationBlock (reviewer comment) to HTML
      class ReviewerComment < Base
        # Convert CoreModel::AnnotationBlock (reviewer comment) to HTML
        def self.to_html(comment, _options = {})
          return '' unless comment

          # Build attributes
          attrs = build_attributes(comment)

          # Process content
          content = process_content(comment.content)

          # Parse reviewer info from metadata
          reviewer_info = extract_reviewer_info(comment.metadata)

          %(<div#{attrs}>
<span class="reviewer-note-label">Reviewer Note</span>
#{reviewer_info}
<div class="reviewer-note-content">
#{content}
</div>
</div>)
        end

        def self.build_attributes(comment)
          attrs = [%( class="reviewer-note")]

          # Add ID if present
          attrs << %( id="#{escape_attribute(comment.id)}") if comment.id

          attrs.join
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

          # Extract reviewer info from metadata
          reviewer = metadata[:reviewer]
          return '' unless reviewer

          %(<div class="reviewer-note-metadata">
<span class="metadata-item">reviewer=#{escape_html(reviewer)}</span>
</div>)
        end
      end
    end
  end
end
