# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        module Inline
          class Underline < Base
            def to_adoc(model, _options = {})
              "[.underline]##{model.text}#"
            end
          end
        end

        # Self-register this serializer
        ElementRegistry.register(Coradoc::AsciiDoc::Model::Inline::Underline, Inline::Underline)
      end
    end
  end
end
