# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class BibliographyEntry < Base
        def self.to_html(entry, _options = {})
          return '' unless entry

          children = []

          entry_id = entry.metadata&.dig(:anchor_name) || entry.metadata&.dig(:document_id) || entry.id
          if entry_id
            anchor = NodeBuilder.build(:a, nil, id: entry_id, class: 'bibliography-anchor')
            children << anchor
          end

          label = entry.metadata&.dig(:label) || entry_id || ''
          unless label.empty?
            label_span = NodeBuilder.build(:span, escape_html(label), class: 'bibliography-label')
            children << label_span
            children << NodeBuilder.text(' ')
          end

          content = entry.content || ''
          content_html = process_content(content)
          children << NodeBuilder.build(:fragment, content_html) unless content_html.empty?

          NodeBuilder.build(:div, children, class: 'bibliography-entry').to_html
        end

        def self.to_coradoc(element, _options = {})
          return nil unless element.name == 'div'
          return nil unless element['class']&.include?('bibliography-entry')

          anchor = element.at_css('.bibliography-anchor, a[id]')
          entry_id = anchor&.[]('id')

          label_elem = element.at_css('.bibliography-label')
          label = label_elem&.text&.strip

          content_nodes = element.children.reject do |node|
            node == anchor || node == label_elem || (node.text? && node.text.strip.empty?)
          end

          content = extract_content(content_nodes)

          Coradoc::CoreModel::Block.new(
            block_semantic_type: 'bibliography_entry',
            content: content,
            id: entry_id,
            metadata: {
              label: label
            }
          )
        end

        def self.process_content(content)
          return '' if content.nil?

          if content.is_a?(String)
            escape_html(content)
          elsif content.is_a?(Array)
            content.map { |item| convert_item(item) }.join
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

        def self.extract_content(nodes)
          nodes.map(&:text).compact.join
        end
      end
    end
  end
end
