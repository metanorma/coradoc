# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        class CodeBlock < ElementSerializer
          handles_type ::Coradoc::Markdown::CodeBlock

          def call(element, _ctx)
            "```#{element.language}\n#{element.code}\n```"
          end
        end
      end
    end
  end
end
