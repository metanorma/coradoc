# frozen_string_literal: true

module Coradoc
  module Reference
    module Presentation
      # One page = the whole document. Use for fixed-structure output
      # (single HTML, single PDF, EPUB chapter). Cross-references
      # always resolve to the single page.
      class SingleDocument < Base
        def layout(resolved_graph)
          [Page.new(
            id: page_id_for(resolved_graph),
            title: resolved_graph.title,
            content: resolved_graph,
            order: 0
          )]
        end

        def locate_page(_edge, _target_content, pages:)
          pages.first
        end

        private

        def page_id_for(node)
          node.id || 'root'
        end
      end
    end
  end
end
