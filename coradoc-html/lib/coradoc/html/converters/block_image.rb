# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for CoreModel::Image (block image)
      class BlockImage < Base
        def self.to_html(model, _state = {})
          img_attrs = {}
          # Remove leading colons from src (source format syntax artifact)
          src = model.src
          src = src.sub(/^:+/, '') if src
          img_attrs[:src] = src if src
          img_attrs[:id] = model.id if model.id
          img_attrs[:alt] = model.alt || model.caption || ''

          # Extract additional attributes
          img_attrs[:width] = model.width if model.width
          img_attrs[:height] = model.height if model.height

          img_element = build_element('img', nil, img_attrs)

          # Wrap in figure if we have a caption
          if model.caption && !model.caption.empty?
            figcaption = build_element('figcaption', model.caption)
            content = "#{img_element}\n#{figcaption}"
            build_element('figure', "\n#{content}\n")
          else
            # Just a plain img element wrapped in a div for block display
            build_element('div', img_element, { class: 'image' })
          end
        end

        def self.to_coradoc(node, _state = {})
          # Handle both <figure> and <div class="image"> cases
          if node.name == 'figure'
            img_node = node.at_css('img')
            return nil unless img_node

            attrs = extract_attributes(img_node)
            figcaption = node.at_css('figcaption')
            caption = figcaption&.text

            Coradoc::CoreModel::Image.new(
              src: attrs[:src],
              id: attrs[:id],
              caption: caption,
              alt: attrs[:alt],
              width: attrs[:width],
              height: attrs[:height],
              inline: false
            )
          elsif node.name == 'div' && node['class'] == 'image'
            img_node = node.at_css('img')
            return nil unless img_node

            attrs = extract_attributes(img_node)

            Coradoc::CoreModel::Image.new(
              src: attrs[:src],
              id: attrs[:id],
              alt: attrs[:alt],
              width: attrs[:width],
              height: attrs[:height],
              inline: false
            )
          end
        end
      end
    end
  end
end
