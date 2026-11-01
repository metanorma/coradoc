# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      # Shared access to a paragraph's numbering (list) attributes.
      #
      # uniword persists w:numPr as NESTED properties:
      #   paragraph.properties.numbering_properties.num_id.value
      #   paragraph.properties.numbering_properties.ilvl.value
      # while the flat integers (properties.num_id / properties.ilvl) are
      # only populated programmatically (builder/YAML API). Readers must
      # consult the nested shape first and fall back to the flat one —
      # documents deserialized from DOCX only ever carry the nested shape.
      #
      # lutaml-model also returns an UninitializedClass sentinel for
      # attributes that were not deserialized from source, so every read
      # is guarded by an Integer type check instead of truthiness.
      module NumberingAccess
        # Numbering definition ID (w:numId) for a paragraph.
        #
        # @param paragraph [Uniword::Wordprocessingml::Paragraph]
        # @return [Integer, nil]
        def paragraph_num_id(paragraph)
          nested_numbering_value(paragraph, :num_id)
        end

        # Numbering level (w:ilvl) for a paragraph.
        #
        # @param paragraph [Uniword::Wordprocessingml::Paragraph]
        # @return [Integer, nil]
        def paragraph_ilvl(paragraph)
          nested_numbering_value(paragraph, :ilvl)
        end

        private

        def nested_numbering_value(paragraph, attribute)
          numbering = paragraph_properties(paragraph)&.numbering_properties
          nested = numbering&.public_send(attribute)
          value = wrapper_value(nested)
          return value if value.is_a?(Integer)

          # Fall back to the flat builder/YAML attribute
          flat = paragraph_properties(paragraph)&.public_send(attribute)
          flat.is_a?(Integer) ? flat : nil
        end

        def paragraph_properties(paragraph)
          paragraph.properties if paragraph.respond_to?(:properties)
        end

        # Unwrap w:numId / w:ilvl element models to their value; sentinel
        # objects (UninitializedClass) and nils fail the Integer check.
        def wrapper_value(node)
          value = node.respond_to?(:value) ? node.value : node
          value.is_a?(Integer) ? value : nil
        end
      end
    end
  end
end
