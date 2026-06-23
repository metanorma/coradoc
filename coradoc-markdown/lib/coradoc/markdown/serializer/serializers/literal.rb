# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        # Literal block: preformatted text with no language hint. Uses an
        # unlabeled fenced code block so the content survives VitePress's
        # Vue template parser (4-space indented code blocks only work in
        # specific contexts and leak `<` characters when not separated by
        # blank lines).
        class Literal < ElementSerializer
          handles_type ::Coradoc::Markdown::Literal

          def call(element, _ctx)
            body = element.content.to_s
            body = body.chomp + "\n" unless body.end_with?("\n")
            "```\n#{body}```\n"
          end
        end
      end
    end
  end
end
