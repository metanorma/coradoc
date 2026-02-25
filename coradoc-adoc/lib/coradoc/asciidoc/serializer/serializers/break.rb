# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        class Break < Base
          def to_adoc(_model, _options = {})
            "\n* * *\n"
          end
        end
      end

      # Self-register this serializer
      ElementRegistry.register(Coradoc::AsciiDoc::Model::Break::ThematicBreak, Serializers::Break)
    end
  end
end
