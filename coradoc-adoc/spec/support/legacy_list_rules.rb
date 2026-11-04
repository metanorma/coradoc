# frozen_string_literal: true

# Frozen copy of the hand-written list rules that the M3 bindings retired
# (transformer/list_rules.rb at 2df0e72). The bound-vs-unbound differential
# applies them to a Transformer subclass as the reference the bindings must
# match; the pure tree-building helper is shared with production.
module LegacyListRules
  def self.apply(transformer_class)
    transformer_class.class_eval do
      # List item
      rule(list_item: subtree(:list_item)) do
        marker = list_item[:marker]
        id = list_item[:id]
        lines = list_item[:lines]
        content = if lines
                    Coradoc::AsciiDoc::Transformer.lines_to_text_elements(lines)
                  else
                    list_item[:text].to_s
                  end
        attached = list_item[:attached]
        nested = list_item[:nested]
        line_break = list_item[:line_break]

        # Convert nested array to proper List object if needed
        if nested.is_a?(Array) && nested.any?
          nested = if nested.all?(Coradoc::AsciiDoc::Model::List::Core)
                     nested.first
                   elsif nested.all?(Coradoc::AsciiDoc::Model::List::Item)
                     first_marker = nested.first.marker
                     if first_marker.to_s.lstrip.start_with?('.', '1', 'a', 'A', 'i', 'I')
                       Coradoc::AsciiDoc::Model::List::Ordered.new(items: nested)
                     else
                       Coradoc::AsciiDoc::Model::List::Unordered.new(items: nested)
                     end
                   else
                     nested
                   end
        end

        Coradoc::AsciiDoc::Model::List::Item.new(
          content: content, id:, marker:, attached:, nested:, line_break:
        )
      end

      # List passthrough
      rule(list: simple(:list)) do
        list
      end

      # Unordered list
      rule(unordered: sequence(:list_items)) do
        Coradoc::AsciiDoc::Model::List::Unordered.new(
          items: list_items
        )
      end

      rule(
        attribute_list: simple(:attribute_list),
        unordered: sequence(:list_items)
      ) do
        Coradoc::AsciiDoc::Model::List::Unordered.new(
          items: list_items,
          attrs: attribute_list
        )
      end

      # Ordered list
      rule(ordered: sequence(:list_items)) do
        Coradoc::AsciiDoc::Model::List::Ordered.new(
          items: list_items
        )
      end

      rule(
        attribute_list: simple(:attribute_list),
        ordered: sequence(:list_items)
      ) do
        Coradoc::AsciiDoc::Model::List::Ordered.new(
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
          text = text.content.to_s if text.is_a?(Coradoc::AsciiDoc::Model::TextElement)
          id = term_data[:id]
          id = id.to_s if id.is_a?(Parsanol::Slice)
          { text: text.to_s, id: id, delimiter: delim.to_s }
        when Coradoc::AsciiDoc::Model::TextElement
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
        split_lines = Coradoc::AsciiDoc::Transformer.split_lines_on_hard_break(data[:lines] || [])
        definition = Coradoc::AsciiDoc::Transformer.lines_to_text_elements(split_lines)
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

        Coradoc::AsciiDoc::Model::List::DefinitionItem.new(terms: terms, contents: definition,
                                                           id: item_id, delimiter: item_delim,
                                                           attached: attached)
      end

      rule(definition_list: sequence(:list_items)) do
        Coradoc::AsciiDoc::Bindings::DefinitionListTree.build_dlist_tree(list_items)
      end

      # Definition list with attribute_list (e.g., [%key])
      rule(
        attribute_list: simple(:attribute_list),
        definition_list: sequence(:list_items)
      ) do
        tree = Coradoc::AsciiDoc::Bindings::DefinitionListTree.build_dlist_tree(list_items)
        tree.attrs = attribute_list if attribute_list
        tree
      end
    end
  end
end
