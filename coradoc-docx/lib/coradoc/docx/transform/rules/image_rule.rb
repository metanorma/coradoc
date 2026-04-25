# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      module Rules
        # Transforms w:drawing and w:pict elements to CoreModel::Image.
        #
        # Extracts image reference data (relationship ID, dimensions, alt text).
        # Binary data extraction is handled by the caller via the image_refs
        # list in Context.
        class ImageRule < Rule
          def matches?(element)
            return false unless defined?(Uniword::Wordprocessingml)

            element.is_a?(Uniword::Wordprocessingml::Drawing) ||
              element.is_a?(Uniword::Wordprocessingml::Picture)
          end

          def apply(element, context)
            ref = extract_reference(element)
            context.register_image(ref)

            CoreModel::Image.new(
              src: ref[:src],
              alt: ref[:alt],
              width: ref[:width],
              height: ref[:height],
              inline: ref[:inline]
            )
          end

          private

          def extract_reference(element)
            case element
            when Uniword::Wordprocessingml::Drawing
              extract_drawing_ref(element)
            when Uniword::Wordprocessingml::Picture
              extract_picture_ref(element)
            else
              { src: nil, alt: nil, width: nil, height: nil, inline: true }
            end
          end

          def extract_drawing_ref(drawing)
            if drawing.inline
              extract_inline_ref(drawing.inline)
            elsif drawing.anchor
              extract_anchor_ref(drawing.anchor)
            else
              { src: nil, alt: nil, width: nil, height: nil, inline: true }
            end
          end

          def extract_inline_ref(inline)
            extent = inline.extent
            doc_pr = inline.doc_properties
            graphic = inline.graphic

            {
              src: extract_embed_ref(graphic),
              alt: doc_pr&.name&.to_s || doc_pr&.id&.to_s,
              width: extent_to_px(extent, :cx),
              height: extent_to_px(extent, :cy),
              inline: true
            }
          end

          def extract_anchor_ref(anchor)
            extent = anchor.extent
            doc_pr = anchor.doc_properties
            graphic = anchor.graphic

            {
              src: extract_embed_ref(graphic),
              alt: doc_pr&.name&.to_s || doc_pr&.id&.to_s,
              width: extent_to_px(extent, :cx),
              height: extent_to_px(extent, :cy),
              inline: false
            }
          end

          def extract_picture_ref(_pict)
            # VML-based pictures — less common, extract basic info
            { src: nil, alt: nil, width: nil, height: nil, inline: true }
          end

          def extract_embed_ref(graphic)
            return nil unless graphic

            graphic_data = graphic.graphic_data
            return nil unless graphic_data

            # Navigate: GraphicData → Picture → BlipFill → Blip → embed
            picture = graphic_data.picture
            return nil unless picture

            blip_fill = picture.blip_fill
            return nil unless blip_fill

            blip = blip_fill.blip
            blip&.embed
          end

          # OOXML uses EMU (English Metric Units): 1 inch = 914400 EMU
          EMU_PER_PX = 9525

          def extent_to_px(extent, dimension)
            return nil unless extent

            value = extent.respond_to?(dimension) ? extent.send(dimension) : nil
            return nil unless value

            px = value.to_i / EMU_PER_PX
            px.positive? ? "#{px}px" : nil
          end
        end
      end
    end
  end
end
