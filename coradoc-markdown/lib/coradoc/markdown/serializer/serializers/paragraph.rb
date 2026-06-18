# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        class Paragraph < ElementSerializer
          handles_type ::Coradoc::Markdown::Paragraph

          def call(element, ctx)
            if element.children.any?
              ctx.serialize_inline_join(element.children)
            else
              element.text.to_s
            end
          end
        end
      end
    end
  end
end
