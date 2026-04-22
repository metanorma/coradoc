# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class DocumentAttributes < Base
          def to_adoc(model, _options = {})
            return '' if model.data.nil?
            return "\n" if model.data.empty?

            model.data.map { |attr| serialize_child(attr) }.join + "\n"
          end
        end
      end

      # Self-register this serializer (in Adoc module scope)
      ElementRegistry.register(Coradoc::AsciiDoc::Model::DocumentAttributes, Serializers::DocumentAttributes)
    end
  end
end
