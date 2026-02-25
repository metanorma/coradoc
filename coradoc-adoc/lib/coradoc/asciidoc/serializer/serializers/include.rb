# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class Include < Base
          def to_adoc(model, _options = {})
            attrs = model.attributes.to_adoc(show_empty: true)
            "include::#{model.path}#{attrs}#{model.line_break}"
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::Include, Serializers::Include)
    end
  end
end
