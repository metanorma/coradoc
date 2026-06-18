# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        class Heading < ElementSerializer
          handles_type ::Coradoc::Markdown::Heading

          def call(element, _ctx)
            "#{'#' * element.level} #{element.text}"
          end
        end
      end
    end
  end
end
