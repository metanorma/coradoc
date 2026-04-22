# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class Tag < Base
          def to_adoc(model, _options = {})
            attrs_str = model.attrs.to_adoc unless model.attrs.nil?
            "// #{model.prefix}::#{model.name}#{attrs_str}#{model.line_break}"
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::Tag, Serializers::Tag)
    end
  end
end
