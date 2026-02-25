# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Inline
          # Serializer for STEM inline formulas
          class Stem < Base
            def to_adoc(model, _options = {})
              content = serialize_content(model.content)
              type = model.type || 'stem'
              "#{type}:[#{content}]"
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coradoc::AsciiDoc::Model::Inline::Stem, Inline::Stem)
      end
    end
  end
end
