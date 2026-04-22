# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class AttributeListAttribute < Base
          def to_adoc(model, _options = {})
            [nil, ''].include?(model.value) ? '""' : model.value
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::AttributeListAttribute, Serializers::AttributeListAttribute)
    end
  end
end
