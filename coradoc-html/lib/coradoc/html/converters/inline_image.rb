# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for CoreModel::Image (inline image)
      class InlineImage < Base
        def self.to_html(model, _state = {})
          attrs = {}
          # Remove leading colons from src (source format syntax artifact)
          src = model.src
          src = src.sub(/^:+/, '') if src
          attrs[:src] = src if src
          attrs[:id] = model.id if model.id
          attrs[:alt] = model.alt || ''

          # Extract additional attributes
          attrs[:width] = model.width if model.width
          attrs[:height] = model.height if model.height

          build_element('img', nil, attrs)
        end

        def self.to_coradoc(node, _state = {})
          return nil unless node.name == 'img'

          attrs = extract_attributes(node)

          Coradoc::CoreModel::Image.new(
            src: attrs[:src],
            id: attrs[:id],
            alt: attrs[:alt],
            width: attrs[:width],
            height: attrs[:height],
            inline: true
          )
        end
      end
    end
  end
end
