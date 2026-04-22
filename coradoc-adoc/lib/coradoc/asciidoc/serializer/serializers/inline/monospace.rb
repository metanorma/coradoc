# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Inline
          # Serializer for Monospace inline formatting
          class Monospace < Base
            def to_adoc(model, _options = {})
              content = serialize_content(model.content)
              content = Coradoc::Util::AsciiDoc.escape_characters(content, escape_chars: ['`'])

              return '' if content.empty?

              model.unconstrained ? "``#{content}``" : "`#{content}`"
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coradoc::AsciiDoc::Model::Inline::Monospace, Inline::Monospace)
      end
    end
  end
end
