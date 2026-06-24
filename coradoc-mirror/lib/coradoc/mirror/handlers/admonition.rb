# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      # Admonition (NOTE, TIP, WARNING, CAUTION, IMPORTANT) handler.
      #
      # The annotation_type is always set from the CoreModel value. When
      # partition_structural is on, the node is built with `js_shape: true`
      # so #to_h emits `attrs.type` (the @metanorma/mirror JS contract);
      # otherwise it emits the legacy `attrs.admonition_type`.
      module Admonition
        def self.call(element, context:)
          content = context.extract_content(element)
          return nil if content.empty?

          Node::Admonition.new(
            id: element.id,
            admonition_type: element.annotation_type,
            title: element.title,
            label: element.annotation_label,
            content: content,
            js_shape: context.partition_structural
          )
        end
      end
    end
  end
end
