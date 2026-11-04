# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Bindings
      # Builds the nested DefinitionList tree for the bound
      # `definition_list` rules (a semantic step too big for pure wiring,
      # kept here as a named helper rather than inside a hook).
      module DefinitionListTree
        module_function

        # Build a nested DefinitionList tree from a flat list of items.
        #
        # AsciiDoc's dlist syntax uses delimiter length to express
        # nesting depth (`::` = 1, `:::` = 2, `::::` = 3). Consecutive
        # term-only items at the SAME depth are merged into a single
        # multi-term `<dt>` sharing the next item's `<dd>`:
        #
        #   term1::            →   <dt>term1</dt>
        #   term2::                <dt>term2</dt>
        #   def                    <dd>def</dd>
        #
        # Stack-based walk in source order. Each item carries its own
        # `delimiter`; depth is derived via {#dlist_depth}.
        def build_dlist_tree(items)
          root = Model::List::Definition.new(items: [])
          stack = [[root, 0]]

          items.each do |item|
            depth = dlist_depth(item.delimiter)
            stack.pop while stack.last[1] >= depth

            parent_list = stack.last[0]
            last = parent_list.items.last

            if merge_with_predecessor?(last, item)
              merge_term_only_item(last, item)
              # Stack stays — deeper items still nest under `last`.
              # Replace the stack top so deeper items land in `last`'s
              # current nested list (already on the stack from when
              # `last` was first added).
            else
              parent_list.items << item
              item.nested << Model::List::Definition.new(items: [])
              stack.push([item.nested.last, depth])
            end
          end

          prune_empty_nested(root)
          root
        end

        # Two consecutive items at the same depth become a multi-term
        # `<dt>` sharing one `<dd>` when the PREVIOUS item is term-only
        # (no def, no attached blocks). The previous item is the
        # accumulating dt; the current item contributes either another
        # term (if it's also term-only) or the terminal dt + the
        # shared dd (if it has a def).
        #
        # Once an item has its own def/attached, it's the terminal dt
        # of any in-progress multi-term group; the next same-depth
        # item starts a fresh entry.
        def merge_with_predecessor?(last, current)
          return false unless last
          return false unless last.delimiter == current.delimiter
          return false unless term_only?(last)

          true
        end

        # "Term-only" means the item carries no dd content of its own
        # (no inline def, no `+`-attached blocks, no nested child
        # items). Such items are eligible to merge with a following
        # same-depth item to form a multi-term `<dt>` sharing one dd.
        # Items with nested children have already "claimed" their dd
        # slot for the nested content and can't merge.
        def term_only?(item)
          return false if contents_present?(item)
          return false if attached_present?(item)
          return false if nested_has_items?(item)

          true
        end

        def contents_present?(item)
          !item.contents.nil? && !item.contents.empty?
        end

        def attached_present?(item)
          !item.attached.nil? && item.attached.any?
        end

        # `item.nested` is an Array<Definition>; each Definition has
        # its own `items` Array. An item with populated nested items
        # (deeper dlist children) is not term-only.
        def nested_has_items?(item)
          Array(item.nested).any? { |list| list.is_a?(Model::List::Definition) && list.items.any? }
        end

        def merge_term_only_item(last, current)
          last.terms.concat(current.terms)
          # contents and attached are arrays; concat is safe (no-op for empty)
          last.contents.concat(current.contents.to_a)
          last.attached.concat(current.attached.to_a)
        end

        def dlist_depth(delimiter)
          delim = delimiter.to_s
          return 1 if delim == ';;' || delim.empty?

          [delim.count(':') - 1, 1].max
        end

        def prune_empty_nested(list)
          list.items.each do |item|
            item.nested.select! do |n|
              n.is_a?(Model::List::Definition) && n.items.any?
            end
            item.nested.each { |n| prune_empty_nested(n) }
          end
        end
      end
    end
  end
end
