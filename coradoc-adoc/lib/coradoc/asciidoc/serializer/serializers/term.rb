# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class Term < Base
          def to_adoc(model, _options = {})
            return "#{model.type}:[#{model.term}]#{model.line_break}" if model.lang.to_s == 'en'

            "[#{model.type}]##{model.term}##{model.line_break}"
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::Term, Serializers::Term)
    end
  end
end
