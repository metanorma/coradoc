# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class Header < Base
          def to_adoc(model, _options = {})
            # Output anchor if ID is present
            adoc = +''
            adoc << "[[#{model.id}]]\n" if model.id && !model.id.empty?
            adoc << "= #{model.title}\n"
            adoc << model.author.to_adoc if model.author
            adoc << model.revision.to_adoc if model.revision
            adoc
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::Header, Serializers::Header)
    end
  end
end
