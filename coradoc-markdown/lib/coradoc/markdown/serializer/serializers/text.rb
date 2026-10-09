# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        class Text < ElementSerializer
          handles_type ::Coradoc::Markdown::Text

          def call(element, _ctx)
            element.content.to_s
          end
        end
      end
    end
  end
end
