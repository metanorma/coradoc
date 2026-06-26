# frozen_string_literal: true

module Coradoc
  module Reference
    module Presentation
      # Splits the document by top-level section (or a configurable
      # boundary). Each section becomes a Page. Cross-references are
      # rewritten to point at whichever page the target content lives on.
      #
      #   SplitPages.new(split_at: :section)  # default
      #   SplitPages.new(split_at: :chapter) # HeaderElement only
      class SplitPages < Base
        attr_reader :split_at

        def initialize(split_at: :section)
          super()
          @split_at = split_at.to_sym
        end

        def layout(resolved_graph)
          children = read_children(resolved_graph)
          return [single_page_for(resolved_graph)] if children.nil? || children.empty?

          sections = children.select { |child| matches_split?(child) }
          return [single_page_for(resolved_graph)] if sections.empty?

          sections.map.with_index { |section, idx| page_for(section, resolved_graph, idx) }
        end

        def locate_page(_edge, target_content, pages:)
          pages.find { |page| owns_target?(page, target_content) }
        end

        private

        def page_for(section, parent, idx)
          Page.new(
            id: section.id || "page-#{idx}",
            title: section.title || "Page #{idx}",
            content: section,
            parent_id: parent.id,
            order: idx
          )
        end

        def read_children(node)
          return nil unless node.is_a?(Coradoc::CoreModel::HasChildren)

          node.children
        end

        def matches_split?(node)
          return false unless node.is_a?(Coradoc::CoreModel::StructuralElement)

          klass = boundary_class
          node.is_a?(klass)
        end

        def boundary_class
          split_at == :chapter ? Coradoc::CoreModel::HeaderElement : Coradoc::CoreModel::SectionElement
        end

        def single_page_for(node)
          Page.new(
            id: node.id || 'root',
            title: node.title,
            content: node,
            order: 0
          )
        end

        def owns_target?(page, target)
          return true if page.content.equal?(target)

          descendant_of?(page.content, target)
        end

        def descendant_of?(ancestor, target)
          return false unless ancestor.is_a?(Coradoc::CoreModel::HasChildren)

          children = ancestor.children
          return false unless children

          children.any? do |child|
            child.equal?(target) || descendant_of?(child, target)
          end
        end
      end
    end
  end
end
