# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        # Literal block: indented code block (4 leading spaces per line).
        # Distinct from a code block (which carries a language hint).
        class Literal < ElementSerializer
          handles_type ::Coradoc::Markdown::Literal

          def call(element, _ctx)
            element.content.to_s.lines.map { |line| "    #{line}" }.join
          end
        end
      end
    end
  end
end
