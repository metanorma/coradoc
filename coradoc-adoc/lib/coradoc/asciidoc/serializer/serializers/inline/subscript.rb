# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Inline
          # Serializer for Subscript inline formatting
          class Subscript < Base
            def to_adoc(model, _options = {})
              content = serialize_content(model.content)
              content = Coradoc::Util::AsciiDoc.escape_characters(
                content,
                pass_through: %w[~]
              )

              return '' if content.empty?

              "~#{content}~"
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coradoc::AsciiDoc::Model::Inline::Subscript, Inline::Subscript)
      end
    end
  end
end
