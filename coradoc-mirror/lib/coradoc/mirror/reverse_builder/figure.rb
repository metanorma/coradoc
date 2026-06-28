# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      # JS @metanorma/mirror `figure` wraps an image plus an optional
      # caption. Reverse: collapse back to a single CoreModel::Image,
      # promoting the caption child to `caption:` if present.
      class Figure < Base
        def build(node)
          image_child = node.content&.find { |c| c.is_a?(Node) && c.type == 'image' }
          return nil unless image_child

          image = build_node(image_child)
          caption = extract_caption(node)
          image.caption = caption if caption && !image.caption
          image
        end

        private

        def extract_caption(node)
          caption_node = node.content&.find { |c| c.is_a?(Node) && c.type == 'caption' }
          return nil unless caption_node

          extract_text(caption_node)
        end
      end
    end
  end
end
