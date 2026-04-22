# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class NamedAttribute < Base
          def to_adoc(model, _options = {})
            if model.value.length == 1
              "#{model.name}=#{model.value.first}"
            else
              "#{model.name}=\"#{model.value.join(' ')}\""
            end
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::NamedAttribute, Serializers::NamedAttribute)
    end
  end
end
