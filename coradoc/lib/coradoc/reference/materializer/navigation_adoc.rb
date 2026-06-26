# frozen_string_literal: true

module Coradoc
  module Reference
    module Materializer
      # Render a navigation edge as AsciiDoc-style xref text. The
      # output is a TextElement containing the asciidoc macro —
      # downstream serialization turns it back into <<target[label]>>.
      class NavigationAdoc < Base
        class << self
          def kind
            :navigation
          end

          def presentation
            :any
          end

          def format
            :asciidoc
          end
        end

        def materialize(edge:, result:, **)
          text = display_text(edge, result)
          Coradoc::CoreModel::TextElement.new(
            content: "<<#{edge.address}|#{text}>>"
          )
        end

        private

        def display_text(edge, result)
          return edge.label if edge.label && !edge.label.empty?
          return result.target.title if result.is_a?(Coradoc::Reference::Result::Resolved) && result.target&.title

          edge.address.to_s
        end
      end
    end
  end
end
