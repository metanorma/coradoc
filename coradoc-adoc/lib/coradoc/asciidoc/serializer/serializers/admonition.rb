# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class Admonition < Base
          def to_adoc(model, _options = {})
            _content = serialize_children(model.content).to_s.strip
            "#{model.type.to_s.upcase}: #{_content}#{model.line_break}"
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::Admonition, Serializers::Admonition)
    end
  end
end
