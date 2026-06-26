# frozen_string_literal: true

module Coradoc
  module Reference
    module Materializer
      # Default fallback. Returns the edge's label (or address) as a
      # plain text element. Use for round-tripping documents we
      # cannot resolve or do not know how to render.
      class Passthrough < Base
        class << self
          def kind
            :any
          end

          def presentation
            :any
          end

          def format
            :any
          end
        end

        def materialize(edge:, result:, **)
          text = display_text(edge, result)
          Coradoc::CoreModel::TextElement.new(content: text)
        end

        private

        def display_text(edge, _result)
          return edge.label if edge.label && !edge.label.empty?

          edge.address.to_s
        end
      end
    end
  end
end
