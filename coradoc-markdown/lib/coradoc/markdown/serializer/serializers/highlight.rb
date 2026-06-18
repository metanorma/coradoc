# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        class Highlight < ElementSerializer
          handles_type ::Coradoc::Markdown::Highlight

          def call(element, _ctx)
            "==#{element.text}=="
          end
        end
      end
    end
  end
end
