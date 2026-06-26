# frozen_string_literal: true

module Coradoc
  module Reference
    module Presentation
      # Protocol base. Subclasses implement +#layout+ (resolved graph →
      # Pages) and +#locate_page+ (find which page a target lives on).
      #
      # A Presentation NEVER reads the original document — it consumes
      # the resolved graph produced by the Resolver. It never renders.
      class Base
        # Lay out the resolved graph as a tree of Pages. Subclasses
        # decide slicing, ordering, hierarchy.
        #
        # @param resolved_graph [CoreModel::Base] the document the
        #   caller wants to present. Already resolved (edges → targets).
        # @return [Array<Page>]
        def layout(resolved_graph)
          raise NotImplementedError
        end

        # Given an Edge and its resolved target, find the Page where
        # the target lives. This is what makes cross-references
        # survive re-pagination.
        #
        # @param edge [Edge]
        # @param target_content [CoreModel::Base]
        # @param pages [Array<Page>]
        # @return [Page, nil]
        def locate_page(edge, target_content, pages:)
          raise NotImplementedError
        end
      end
    end
  end
end
