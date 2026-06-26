# frozen_string_literal: true

module Coradoc
  module Reference
    module Materializer
      # Render a navigation edge (:navigation kind) as an HTML-shaped
      # CoreModel::LinkElement. The href is computed by asking the
      # Presentation where the target lives (so the same edge renders
      # to different hrefs under different presentations).
      class NavigationHtml < Base
        class << self
          def kind
            :navigation
          end

          def presentation
            :any
          end

          def format
            :html
          end
        end

        def materialize(edge:, result:, presentation:, pages:)
          href = href_for(edge, result, presentation, pages)
          text = display_text(edge, result)
          Coradoc::CoreModel::LinkElement.new(
            target: href,
            content: text,
            children: [
              Coradoc::CoreModel::TextElement.new(content: text)
            ]
          )
        end

        private

        def href_for(edge, result, presentation, pages)
          return edge.address.to_s unless result.is_a?(Coradoc::Reference::Result::Resolved)
          return edge.address.to_s unless presentation && pages

          page = presentation.locate_page(edge, result.target, pages: pages)
          return edge.address.to_s unless page

          build_href(page, edge, result.target)
        end

        def build_href(page, _edge, target)
          anchor = anchor_for(target)
          anchor ? "##{anchor}" : page_path(page)
        end

        def page_path(page)
          page.id || '#'
        end

        def anchor_for(target)
          target.id if target.is_a?(Coradoc::CoreModel::Base) && target.id
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
