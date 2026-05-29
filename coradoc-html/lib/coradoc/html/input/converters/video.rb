# frozen_string_literal: true

require_relative 'media_base'

module Coradoc
  module Input
    module Html
      module Converters
        class Video < MediaBase
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

        register :video, Video.new
      end
    end
  end
end
