# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Inline
          # Serializer for Italic inline formatting
          class Italic < Base
            def to_adoc(model, _options = {})
              content = serialize_content(model.content)
              content = Coradoc::Util::AsciiDoc.escape_characters(content, escape_chars: ['_'])

              return '' if content.empty?

              model.unconstrained ? "__#{content}__" : "_#{content}_"
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coradoc::AsciiDoc::Model::Inline::Italic, Inline::Italic)
      end
    end
  end
end
