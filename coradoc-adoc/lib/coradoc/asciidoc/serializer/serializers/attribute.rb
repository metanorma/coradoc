# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class Attribute < Base
          # Pre-compiled regex for performance
          QUOTE_REGEX = /^'|'$/

          def to_adoc(model, _options = {})
            _value = model.value.to_s.gsub(QUOTE_REGEX, '') # Remove surrounding single quotes
            v = _value.empty? ? '' : " #{_value}"
            ":#{model.key}:#{v}#{model.line_break}"
          end
        end
      end

      # Self-register this serializer (in Adoc module scope)
      ElementRegistry.register(Coradoc::AsciiDoc::Model::Attribute, Serializers::Attribute)
    end
  end
end
