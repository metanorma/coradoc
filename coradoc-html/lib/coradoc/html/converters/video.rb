# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Video < MediaBase
        INSTANCE = new

        private

        def semantic_type
          :video
        end

        def build_attributes(node)
          base_attributes(node).merge(
            poster: node['poster'],
            width: node['width'],
            height: node['height']
          ).compact
        end
      end

      register :video, Video::INSTANCE
    end
  end
end
