# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        class Image < ElementSerializer
          handles_type ::Coradoc::Markdown::Image

          def call(element, _ctx)
            "![#{element.alt}](#{element.src}#{element.title ? " \"#{element.title}\"" : ''})"
          end
        end
      end
    end
  end
end
