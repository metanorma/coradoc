# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      # Image handler.
      #
      # Two emission shapes:
      #   - Ruby legacy (default): bare `image` node, title/caption in attrs.
      #   - JS @metanorma/mirror (`partition_structural: true`): when the
      #     source image has a title, wrap it in a `figure` node with the
      #     image plus a `caption` child, matching the JS schema.
      module Image
        def self.call(element, context:)
          image_node = build_image_node(element)

          return image_node unless context.partition_structural
          return image_node unless caption_text?(element)

          Node::Figure.new(
            attrs: Node::Figure::Attrs.new(id: element.id, title: caption_value(element)),
            content: [image_node, Node::Caption.new(content: caption_text_nodes(element, context))]
          )
        end

        class << self
          private

          def build_image_node(element)
            Node::Image.new(
              attrs: Node::Image::Attrs.new(
                src: element.src,
                alt: element.alt,
                title: element.title,
                caption: element.caption,
                width: element.width,
                height: element.height,
                inline: element.inline || nil
              )
            )
          end

          def caption_text?(element)
            !caption_value(element).to_s.empty?
          end

          def caption_value(element)
            element.caption || element.title
          end

          def caption_text_nodes(element, context)
            [context.text_node(caption_value(element).to_s)]
          end
        end
      end
    end
  end
end
