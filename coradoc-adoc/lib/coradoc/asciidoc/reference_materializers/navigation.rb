# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module ReferenceMaterializers
      # Render a navigation edge as a first-class CrossReferenceElement
      # — the model-driven xref node the AsciiDoc serializer already
      # knows how to emit (never a raw macro string). Materializing for
      # AsciiDoc fills in the visible text from the authored label or
      # the resolved target's title.
      class Navigation < Coradoc::Reference::Materializer::Base
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
          Coradoc::CoreModel::CrossReferenceElement.new(
            target: xref_target(edge.address),
            content: text,
            children: [
              Coradoc::CoreModel::TextElement.new(content: text)
            ]
          )
        end

        private

        def xref_target(address)
          [address.target, address.fragment].compact.join('#')
        end

        def display_text(edge, result)
          return edge.label if edge.label && !edge.label.empty?
          return result.target.title if result.is_a?(Coradoc::Reference::Result::Resolved) && result.target&.title

          edge.address.to_s
        end
      end
    end
  end
end
