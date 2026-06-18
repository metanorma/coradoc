# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        class Abbreviation < ElementSerializer
          handles_type ::Coradoc::Markdown::Abbreviation

          def call(element, _ctx)
            "*[#{element.term}]: #{element.definition}"
          end
        end
      end
    end
  end
end
