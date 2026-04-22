# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for CoreModel::Block (bibliography entry) to HTML bibliography entry
      class BibliographyEntry < Base
        # Convert CoreModel::Block (bibliography entry) to HTML bibliography entry
        def self.to_html(entry, _options = {})
          return '' unless entry

          # Build entry attributes
          attrs = build_attributes(entry)

          # Get entry ID from metadata
          entry_id = entry.metadata&.dig(:anchor_name) || entry.metadata&.dig(:document_id) || entry.id

          # Build anchor if ID present
          anchor_html = if entry_id
                          %(<a id="#{escape_attribute(entry_id)}" class="bibliography-anchor"></a>)
                        else
                          ''
                        end

          # Get citation label
          label = entry.metadata&.dig(:label) || entry_id || ''

          # Get entry reference text
          content = entry.content || ''

          # Process content
          content_html = process_content(content)

          # Combine into entry
          entry_html = anchor_html
          entry_html += %(<span class="bibliography-label">#{escape_html(label)}</span> ) unless label.empty?
          entry_html += content_html

          %(<div#{attrs}>#{entry_html}</div>)
        end

        # Convert HTML bibliography entry to CoreModel::Block (bibliography entry)
        def self.to_coradoc(element, _options = {})
          return nil unless element.name == 'div'
          return nil unless element['class']&.include?('bibliography-entry')

          # Extract anchor/ID
          anchor = element.at_css('.bibliography-anchor, a[id]')
          entry_id = anchor&.[]('id')

          # Extract label
          label_elem = element.at_css('.bibliography-label')
          label = label_elem&.text&.strip

          # Extract content (everything except anchor and label)
          content_nodes = element.children.reject do |node|
            node == anchor || node == label_elem || (node.text? && node.text.strip.empty?)
          end

          content = extract_content(content_nodes)

          Coradoc::CoreModel::Block.new(
            element_type: 'bibliography_entry',
            content: content,
            id: entry_id,
            metadata: {
              label: label
            }
          )
        end

        def self.build_attributes(_entry)
          %( class="bibliography-entry")
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
          # Extract and convert content nodes
          nodes.map do |node|
            if node.text?
            end
            node.text
          end.compact.join
        end
      end
    end
  end
end
