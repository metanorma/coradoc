# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class LineBreak < Base
          def to_adoc(model, _options = {})
            model.line_break
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::LineBreak, Serializers::LineBreak)
    end
  end
end
