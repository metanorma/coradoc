# frozen_string_literal: true

module Coradoc
  module Reference
    module Presentation
      # Caller-supplied hierarchy. The user provides a tree of node ids
      # mapping to pages; the presentation lays out content accordingly.
      # This is the presentation website builds use.
      #
      #   CustomHierarchy.new(hierarchy: [
      #     { id: "intro", title: "Introduction", children: [...] },
      #     { id: "chap1", title: "Chapter 1", children: [
      #       { id: "chap1-1", title: "1.1" }
      #     ] }
      #   ])
      class CustomHierarchy < Base
        attr_reader :hierarchy

        def initialize(hierarchy:)
          super()
          @hierarchy = normalize_hierarchy(hierarchy)
        end

        def layout(resolved_graph)
          pages = []
          walk_hierarchy(@hierarchy, parent_id: nil, pages: pages, root: resolved_graph)
          pages.each_with_index { |p, i| p.order = i }
          pages
        end

        def locate_page(_edge, target_content, pages:)
          pages.find { |page| page.content.equal?(target_content) }
        end

        private

        def normalize_hierarchy(tree)
          Array(tree).map do |entry|
            entry.merge(children: normalize_hierarchy(entry[:children]))
          end
        end

        def walk_hierarchy(nodes, parent_id:, pages:, root:)
          nodes.each do |entry|
            content = find_content_by_id(root, entry[:id]) || root
            pages << Page.new(
              id: entry[:id],
              title: entry[:title] || content.title,
              content: content,
              parent_id: parent_id
            )
            walk_hierarchy(entry[:children], parent_id: entry[:id], pages: pages, root: root)
          end
        end

        def find_content_by_id(root, id)
          return nil unless id

          visitor = VisitorById.new(id)
          visitor.visit(root)
          visitor.found
        end

        # Single-purpose visitor: walks a CoreModel tree looking for
        # one node by id. Cleaner than a recursive method on the
        # presentation class itself.
        class VisitorById
          attr_reader :found

          def initialize(target_id)
            @target_id = target_id
            @found = nil
          end

          def visit(node)
            return @found if @found
            return unless node.is_a?(Coradoc::CoreModel::Base)

            @found = node if node.id == @target_id
            return if @found

            visit_children(node)
          end

          private

          def visit_children(node)
            return unless node.is_a?(Coradoc::CoreModel::HasChildren)

            children = node.children
            return unless children

            children.each { |c| visit(c) }
            nil
          end
        end
      end
    end
  end
end
