# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Inline
          # Serializer for Strikethrough inline formatting
          class Strikethrough < Base
            def to_adoc(model, _options = {})
              content = serialize_content(model.content || model.text)

              return '' if content.empty?

              if model.respond_to?(:unconstrained) && model.unconstrained
                "[.line-through]#[.line-through]##{content}[.line-through]#[.line-through]#"
              else
                "[.line-through]##{content}#"
              end
            end
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::Inline::Strikethrough, Serializers::Inline::Strikethrough)
    end
  end
end
