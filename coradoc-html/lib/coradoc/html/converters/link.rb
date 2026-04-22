# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Link < Base
        def self.to_html(model, _state = {})
          # Handle CoreModel::InlineElement with format_type "link"
          attrs = {}
          attrs[:href] = model.target if model.target
          attrs[:id] = model.id if model.id

          # Get title from metadata
          if model.respond_to?(:metadata) && model.metadata && model.metadata[:title]
            attrs[:title] =
              model.metadata[:title]
          end

          # Determine link text - use content or target
          text = model.content || model.target || ''
          build_element('a', text, attrs)
        end

        def self.to_coradoc(node, _state = {})
          return nil unless node.name == 'a'

          attrs = extract_attributes(node)
          href = attrs[:href] || ''
          title = attrs[:title]
          text = node.text

          # If text equals href, don't set text (empty link text)
          text = nil if text == href

          Coradoc::CoreModel::InlineElement.new(
            format_type: 'link',
            target: href,
            content: text,
            metadata: { title: title }.compact,
            id: attrs[:id]
          )
        end
      end
    end
  end
end
