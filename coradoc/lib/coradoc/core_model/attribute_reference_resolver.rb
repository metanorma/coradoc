# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Walks a CoreModel tree and resolves InlineElement nodes whose
    # format_type is 'attribute_reference' against a Metadata store.
    #
    # AsciiDoc `{foo}` references round-trip as InlineElement with
    # format_type: 'attribute_reference' and target: 'foo'. After the
    # document is parsed and its attributes are known, this visitor
    # rewrites those nodes in place to TextContent carrying the value.
    # Unresolved references are left untouched so they survive
    # serialisation back to the source format.
    #
    # The visitor never mutates its input tree; it returns a new tree
    # sharing unchanged subtrees. InlineElement#with_content already
    # produces non-mutating copies for inline content; the same pattern
    # is used here at the block level via `replace_children`.
    class AttributeReferenceResolver
      attr_reader :attributes

      def self.call(root, attributes)
        new(attributes).visit(root)
      end

      def initialize(attributes)
        @attributes = attributes || Metadata.new
      end

      def visit(node)
        return node.map { |child| visit(child) } if node.is_a?(Array)

        return node unless node.is_a?(Base)

        visit_typed(node)
      end

      private

      def visit_typed(node)
        case node
        when DocumentElement, SectionElement
          rebuild_children(node)
        when Table
          rebuild_collection(node, :rows)
        when TableRow
          rebuild_collection(node, :cells)
        when Block, ParagraphBlock, ListItem, TableCell, Term,
             QuoteBlock, ExampleBlock, SidebarBlock, OpenBlock,
             AnnotationBlock, ReviewerBlock, VerseBlock, LiteralBlock,
             PassBlock, StemBlock, ListingBlock, SourceBlock,
             CommentBlock, FrontmatterBlock
          rebuild_block(node)
        when DefinitionList, DefinitionItem
          rebuild_children(node)
        when InlineElement, RawInlineElement
          resolve_inline(node)
        else
          node
        end
      end

      def rebuild_children(node)
        return node unless node.respond_to?(:children)

        original = node.children
        return node if original.nil?

        updated = original.is_a?(Array) ? original.map { |c| visit(c) } : visit(original)
        return node if updated == original

        node.dup.tap { |copy| copy.children = updated }
      end

      # For nodes whose child collection lives on a non-`children`
      # attribute (Table#rows, TableRow#cells). Walks the collection,
      # rebuilds the parent only when at least one child changed.
      def rebuild_collection(node, attr_name)
        original = node.public_send(attr_name)
        return node if original.nil?

        updated = original.is_a?(Array) ?
                    original.map { |c| visit(c) } :
                    visit(original)
        return node if updated == original

        node.dup.tap { |copy| copy.public_send("#{attr_name}=", updated) }
      end

      def rebuild_block(node)
        return node unless node.respond_to?(:children)

        original_children = node.children
        return node if original_children.nil?

        updated_children = original_children.is_a?(Array) ?
                             original_children.map { |c| visit(c) } :
                             visit(original_children)

        if inline_resolvable?(node)
          original_content = node.content
          updated_content = resolve_content(original_content)
        else
          updated_content = node.content
        end

        return node if updated_children == original_children && updated_content == node.content

        node.dup.tap do |copy|
          copy.children = updated_children
          copy.content = updated_content if inline_resolvable?(node)
        end
      end

      def inline_resolvable?(node)
        node.respond_to?(:content) && node.content.is_a?(String)
      end

      # Resolve attribute references inside a flat content string.
      # Only replaces `{name}` when +name+ exists in +attributes+;
      # unknown references are preserved verbatim for round-trip.
      def resolve_content(content)
        return content unless content.is_a?(String)

        content.gsub(/\{([a-zA-Z0-9_-]+)\}/) do |match|
          name = Regexp.last_match(1)
          attributes.key?(name) ? attributes[name].to_s : match
        end
      end

      def resolve_inline(node)
        return node unless node.is_a?(InlineElement)
        return node unless node.resolve_format_type == 'attribute_reference'

        target = node.target
        return node if target.nil? || target.empty?
        return node unless attributes.key?(target)

        TextContent.new(text: attributes[target].to_s)
      end
    end
  end
end
