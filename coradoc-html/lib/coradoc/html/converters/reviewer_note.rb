# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class ReviewerNote < Base
        def self.to_html(reviewer_note, options = {})
          return '' unless reviewer_note

          attrs = build_attributes(reviewer_note)
          header = build_header(reviewer_note)
          content = process_content(reviewer_note.content, options)

          children = []
          children << NodeBuilder.build(:fragment, header) unless header.empty?
          children << NodeBuilder.build(:div, content, class: 'reviewer-note-content')

          NodeBuilder.build(:aside, children, **attrs).to_html
        end

        def self.to_coradoc(element, _options = {})
          return nil unless element.name == 'aside'
          return nil unless element['data-reviewer']

          reviewer = element['data-reviewer']
          date = element['data-date']
          from = element['data-from']
          to = element['data-to']

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
          metadata = reviewer_note.metadata || {}

          children = []
          children << NodeBuilder.build(:span, "Reviewer's note", class: 'reviewer-note-label')

          metadata_items = []
          metadata_items << "reviewer=#{escape_html(metadata[:reviewer])}" if metadata[:reviewer]
          metadata_items << "date=#{escape_html(metadata[:date])}" if metadata[:date]
          metadata_items << "from=#{escape_html(metadata[:from])}" if metadata[:from]
          metadata_items << "to=#{escape_html(metadata[:to])}" if metadata[:to]

          unless metadata_items.empty?
            spans = metadata_items.map { |item| NodeBuilder.build(:span, item, class: 'metadata-item') }
            children << NodeBuilder.build(:div, spans, class: 'reviewer-note-metadata')
          end

          header = NodeBuilder.build(:div, children, class: 'reviewer-note-header')
          header.to_html
        end

        def self.build_attributes(reviewer_note)
          attrs = { class: 'reviewer-note' }
          attrs[:id] = reviewer_note.id if reviewer_note.id

          metadata = reviewer_note.metadata || {}
          attrs[:'data-reviewer'] = metadata[:reviewer].to_s if metadata[:reviewer]
          attrs[:'data-date'] = metadata[:date].to_s if metadata[:date]
          attrs[:'data-from'] = metadata[:from].to_s if metadata[:from]
          attrs[:'data-to'] = metadata[:to].to_s if metadata[:to]

          attrs
        end

        def self.process_content(content, options = {})
          return '' if content.nil?

          if content.is_a?(Array)
            content.map { |item| convert_item(item, options) }.join("\n")
          elsif content.is_a?(String)
            NodeBuilder.build(:p, escape_html(content)).to_html
          else
            convert_item(content, options)
          end
        end

        def self.convert_item(item, _options = {})
          case item
          when String
            NodeBuilder.build(:p, escape_html(item)).to_html
          else
            convert_content_to_html(item)
          end
        end

        def self.extract_content(nodes)
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
