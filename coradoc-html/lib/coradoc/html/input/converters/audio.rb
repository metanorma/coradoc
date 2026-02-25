# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Audio < Base
          def to_coradoc(node, _state = {})
            src = node['src']
            id = node['id']
            title = extract_title(node)
            options(node)

            # Use Block with custom attributes to store audio info
            # CoreModel doesn't have a specific Audio type, so we use Block
            # with element_attributes to store audio-specific data
            Coradoc::CoreModel::Block.new(
              element_type: 'audio',
              delimiter_type: 'audio',
              content: src,
              title: title,
              id: id,
              element_attributes: {
                autoplay: node['autoplay'],
                loop: node['loop'],
                controls: node['controls']
              }.compact
            )
          end

          def extract_title(node)
            title = node.at('./track') || node.at('.//source')
            return '' if title.nil?

            title['label'] || title['srclang'] || ''
          end

          def options(node)
            autoplay = node['autoplay']
            loop_attr = node['loop']
            controls = node['controls']
            [autoplay, loop_attr, controls].compact
          end
        end

        register :audio, Audio.new
      end
    end
  end
end
