# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Inline
          # Serializer for Superscript inline formatting
          class Superscript < Base
            def to_adoc(model, _options = {})
              content = serialize_content(model.content)
              # Superscript uses ^ delimiters, no need to escape

              return '' if content.empty?

              "^#{content}^"
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coradoc::AsciiDoc::Model::Inline::Superscript, Inline::Superscript)
      end
    end
  end
end
