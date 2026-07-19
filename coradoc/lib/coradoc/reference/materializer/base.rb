# frozen_string_literal: true

module Coradoc
  module Reference
    module Materializer
      # Protocol base. Subclasses declare their (kind, presentation,
      # format) tuple via class-level +.kind+, +.presentation+, +.format+
      # methods, then implement +#materialize+ to produce a
      # CoreModel::InlineElement subtree.
      #
      # Materializers consume Results — they never touch the catalog
      # directly. The Presentation tells them where the target lives.
      class Base
        class << self
          def kind
            nil
          end

          def presentation
            :any
          end

          def format
            :any
          end
        end

        # Render one resolved edge.
        #
        # @param edge [Edge]
        # @param result [Result::Base] the resolved outcome
        # @param node [CoreModel::Base] the original edge-bearing node;
        #   return it unchanged to keep the node as authored
        # @param presentation [Presentation::Base]
        # @param pages [Array<Presentation::Page>]
        # @return [CoreModel::Base, nil] replacement node, the original
        #   +node+ to keep it, or nil to drop it from the tree
        def materialize(edge:, result:, node:, presentation:, pages:)
          raise NotImplementedError
        end
      end
    end
  end
end
