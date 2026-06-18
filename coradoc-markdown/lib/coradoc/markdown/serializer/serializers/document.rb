# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        class Document < ElementSerializer
          handles_type ::Coradoc::Markdown::Document

          def call(element, ctx)
            body = element.blocks.map { |block| ctx.serialize(block) }.join("\n\n")
            return body unless element.frontmatter && !element.frontmatter.empty?

            "---\n#{element.frontmatter}---\n\n#{body}".strip
          end
        end
      end
    end
  end
end
