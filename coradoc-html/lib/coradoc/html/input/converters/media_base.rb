# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class MediaBase < Base
          def to_coradoc(node, _state = {})
            src = node['src']
            id = node['id']
            title = extract_title(node)

            Coradoc::CoreModel::Block.new(
              block_semantic_type: semantic_type,
              content: src,
              title: title,
              id: id,
              element_attributes: build_attributes(node)
            )
          end

          def extract_title(node)
            track = node.at('./track') || node.at('.//source')
            return '' if track.nil?

            track['label'] || track['srclang'] || ''
          end

          private

          def semantic_type
            raise NotImplementedError
          end

          def base_attributes(node)
            {
              autoplay: node['autoplay'],
              loop: node['loop'],
              controls: node['controls']
            }.compact
          end

          def build_attributes(node)
            base_attributes(node)
          end
        end
      end
    end
  end
end
