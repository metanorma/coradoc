# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class Author < Base
          def to_adoc(model, _options = {})
            adoc = [model.first_name, model.middle_name, model.last_name].compact.join(' ')
            adoc << " <#{model.email}>\n" if model.email
            adoc
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::Author, Serializers::Author)
    end
  end
end
