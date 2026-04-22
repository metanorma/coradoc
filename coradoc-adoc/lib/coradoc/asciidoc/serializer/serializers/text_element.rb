# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        # Serializer for TextElement models
        class TextElement < Base
          def to_adoc(model, _options = {})
            result = ''
            result += "[[#{model.id}]] " if model.id
            result += serialize_content(model.content)
            result += model.line_break.to_s
            result
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::TextElement, Serializers::TextElement)
    end
  end
end
