# frozen_string_literal: true

module Coradoc
  module Reference
    module Materializer
      # Render a hyperlink edge as a LinkElement with the URL as target.
      # The catalog is not consulted — links are external by definition.
      class LinkHtml < Base
        class << self
          def kind
            :link
          end

          def presentation
            :any
          end

          def format
            :html
          end
        end

        def materialize(edge:, **)
          text = display_text(edge)
          Coradoc::CoreModel::LinkElement.new(
            target: edge.address.to_s,
            content: text,
            children: [
              Coradoc::CoreModel::TextElement.new(content: text)
            ]
          )
        end

        private

        def display_text(edge)
          return edge.label if edge.label && !edge.label.empty?

          edge.address.to_s
        end
      end
    end
  end
end
