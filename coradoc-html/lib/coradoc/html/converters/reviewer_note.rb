# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for CoreModel::AnnotationBlock (reviewer note) to HTML <aside>
      class ReviewerNote < Base
        # Convert CoreModel::AnnotationBlock (reviewer note) to HTML <aside>
        def self.to_html(reviewer_note, options = {})
          return '' unless reviewer_note

          # Build aside attributes with reviewer metadata
          attrs = build_attributes(reviewer_note)

          # Build header with label and visible metadata
          header = build_header(reviewer_note)

          # Process reviewer note content
          content = process_content(reviewer_note.content, options)

          %(<aside#{attrs}>\n#{header}#{content}\n</div>\n</aside>)
        end

        # Convert HTML <aside> with reviewer data to CoreModel::AnnotationBlock
        def self.to_coradoc(element, _options = {})
          return nil unless element.name == 'aside'
          return nil unless element['data-reviewer'] # Must have reviewer attribute

          # Extract reviewer metadata
          reviewer = element['data-reviewer']
          date = element['data-date']
          from = element['data-from']
          to = element['data-to']

          # Extract content
          content = extract_content(element.children)

          Coradoc::CoreModel::AnnotationBlock.new(
            annotation_type: 'reviewer_note',
            content: content,
            metadata: {
              reviewer: reviewer,
              date: date,
              from: from,
              to: to
            }
          )
        end

        def self.build_header(reviewer_note)
          # Build header with label and visible metadata
          header_parts = []
          header_parts << %(<div class="reviewer-note-header">)
          header_parts << %(  <span class="reviewer-note-label">Reviewer's note</span>)

          # Build metadata display if any metadata exists
          metadata_items = []
          metadata = reviewer_note.metadata || {}
          metadata_items << %(reviewer=#{escape_html(metadata[:reviewer])}) if metadata[:reviewer]
          metadata_items << %(date=#{escape_html(metadata[:date])}) if metadata[:date]
          metadata_items << %(from=#{escape_html(metadata[:from])}) if metadata[:from]
          metadata_items << %(to=#{escape_html(metadata[:to])}) if metadata[:to]

          unless metadata_items.empty?
            header_parts << %(  <div class="reviewer-note-metadata">)
            metadata_items.each do |item|
              header_parts << %(    <span class="metadata-item">#{item}</span>)
            end
            header_parts << %(  </div>)
          end

          header_parts << %(</div>)
          header_parts << %(<div class="reviewer-note-content">)

          header_parts.join("\n")
        end

        def self.build_attributes(reviewer_note)
          attrs = [%( class="reviewer-note")]

          # Add reviewer metadata as data attributes
          metadata = reviewer_note.metadata || {}

          attrs << %( data-reviewer="#{escape_html(metadata[:reviewer])}") if metadata[:reviewer]

          attrs << %( data-date="#{escape_html(metadata[:date])}") if metadata[:date]

          attrs << %( data-from="#{escape_html(metadata[:from])}") if metadata[:from]

          attrs << %( data-to="#{escape_html(metadata[:to])}") if metadata[:to]

          attrs.join
        end

        def self.process_content(content, options = {})
          return '' if content.nil?

          if content.is_a?(Array)
            content.map { |item| convert_item(item, options) }.join("\n")
          elsif content.is_a?(String)
            "<p>#{escape_html(content)}</p>"
          else
            convert_item(content, options)
          end
        end

        def self.convert_item(item, _options = {})
          case item
          when String
            "<p>#{escape_html(item)}</p>"
          else
            convert_content_to_html(item)
          end
        end

        def self.extract_content(nodes)
          # Extract and convert content nodes
          nodes.map do |node|
            if node.text? && !node.text.strip.empty?
              node.text.strip
            elsif node.element?
              case node.name
              when 'p'
                Paragraph.to_coradoc(node)
              else
                node.text.strip
              end
            end
          end.compact
        end
      end
    end
  end
end
