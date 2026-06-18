# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        class Superscript < ElementSerializer
          handles_type ::Coradoc::Markdown::Superscript

          def call(element, _ctx)
            "<sup>#{element.text}</sup>"
          end
        end
      end
    end
  end
end
