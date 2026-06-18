# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        class Blockquote < ElementSerializer
          handles_type ::Coradoc::Markdown::Blockquote

          def call(element, _ctx)
            element.content.to_s.lines.map { |line| "> #{line}" }.join
          end
        end
      end
    end
  end
end
