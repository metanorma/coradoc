# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    class Transformer < Parsanol::Transform
      # Module containing list transformation rules
      module ListRules
        class << self
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

        def self.apply(transformer_class)
          transformer_class.class_eval do
            # List item
            rule(list_item: subtree(:list_item)) do
              marker = list_item[:marker]
              id = list_item[:id]
              lines = list_item[:lines]
              content = if lines
                          Transformer.lines_to_text_elements(lines)
                        else
                          list_item[:text].to_s
                        end
              attached = list_item[:attached]
              nested = list_item[:nested]
              line_break = list_item[:line_break]

              # Convert nested array to proper List object if needed
              if nested.is_a?(Array) && nested.any?
                nested = if nested.all?(Model::List::Core)
                           nested.first
                         elsif nested.all?(Model::List::Item)
                           first_marker = nested.first.marker
                           if first_marker.to_s.lstrip.start_with?('.', '1', 'a', 'A', 'i', 'I')
                             Model::List::Ordered.new(items: nested)
                           else
                             Model::List::Unordered.new(items: nested)
                           end
                         else
                           nested
                         end
              end

              Model::List::Item.new(
                content: content, id:, marker:, attached:, nested:, line_break:
              )
            end

            # List passthrough
            rule(list: simple(:list)) do
              list
            end

            # Unordered list
            rule(unordered: sequence(:list_items)) do
              Model::List::Unordered.new(
                items: list_items
              )
            end

            rule(
              attribute_list: simple(:attribute_list),
              unordered: sequence(:list_items)
            ) do
              Model::List::Unordered.new(
                items: list_items,
                attrs: attribute_list
              )
            end

            # Ordered list
            rule(ordered: sequence(:list_items)) do
              Model::List::Ordered.new(
                items: list_items
              )
            end

            rule(
              attribute_list: simple(:attribute_list),
              ordered: sequence(:list_items)
            ) do
              Model::List::Ordered.new(
                items: list_items,
                attrs: attribute_list
              )
            end

            # Definition list term (with optional anchor)
            rule(dlist_term: subtree(:term_data), delimiter: simple(:delim)) do
              case term_data
              when Hash
                text = term_data[:text]
                text = text.to_s if text.is_a?(Parsanol::Slice) || text.is_a?(String)
                text = text.content.to_s if text.is_a?(Model::TextElement)
                id = term_data[:id]
                id = id.to_s if id.is_a?(Parsanol::Slice)
                { text: text.to_s, id: id, delimiter: delim.to_s }
              when Model::TextElement
                { text: term_data.content.to_s, id: term_data.id, delimiter: delim.to_s }
              else
                { text: term_data.to_s, id: nil, delimiter: delim.to_s }
              end
            end

            # Definition list item. The parser's dlist_definition rule
            # always emits :lines (one entry per source line of the dd,
            # including the single-line case as a one-element array).
            # Join via the shared lines_to_text_elements helper used by
            # ulist/olist — single source of truth for line joining.
            # `attached:` carries any `+`-continuation blocks captured by
            # the parser; pass through to the model so downstream stages
            # can render them as additional dd children.
            rule(
              definition_list_item: subtree(:item_data)
            ) do
              data = item_data.is_a?(Hash) ? item_data : { terms: Array(item_data), lines: [] }

              item_id = nil
              item_delim = '::'
              terms_data = data[:terms]
              # Split lines on hard_line_break so each source line is one
              # entry. Without this, text_any greedy-matches across
              # newlines via hard_line_break, joining what should be
              # separate source lines into one entry (and swallowing the
              # `+` line-continuation marker).
              split_lines = Transformer.split_lines_on_hard_break(data[:lines] || [])
              definition = Transformer.lines_to_text_elements(split_lines)
              attached = Array(data[:attached])

              terms = Array(terms_data).map do |t|
                case t
                when Hash
                  item_id ||= t[:id].to_s if t[:id]
                  item_delim = t[:delimiter].to_s if t[:delimiter]
                  t[:text].to_s
                else
                  t.to_s
                end
              end

              Model::List::DefinitionItem.new(terms: terms, contents: definition,
                                              id: item_id, delimiter: item_delim,
                                              attached: attached)
            end

            rule(definition_list: sequence(:list_items)) do
              ListRules.build_dlist_tree(list_items)
            end

            # Definition list with attribute_list (e.g., [%key])
            rule(
              attribute_list: simple(:attribute_list),
              definition_list: sequence(:list_items)
            ) do
              tree = ListRules.build_dlist_tree(list_items)
              tree.attrs = attribute_list if attribute_list
              tree
            end
          end
        end
      end
    end
  end
end
