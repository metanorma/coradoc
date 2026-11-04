# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    # PARG bindings for the AsciiDoc grammar (M3 of the parg-bindings
    # migration): raw-tree rules that inflate straight to model classes
    # through Coradoc::BindingInflater. Every rule not listed here is
    # still handled by Transformer's rule modules (the residual), so the
    # set grows one rule at a time and each bound rule retires its
    # transformer rule.
    #
    # Semantic steps live in small named hooks (`via:`) in Hooks; a hook
    # that keeps growing is a grammar-shape problem, not a hook problem.
    module Bindings
      autoload :DefinitionListTree, "#{__dir__}/bindings/definition_list_tree"

      Binding = Coradoc::BindingInflater::Binding

      # Named hooks: the ~20% of rules that are not pure
      # capture-to-attribute wiring.
      module Hooks
        module_function

        # Header: flatten the raw `{title:, author:, revision:}` capture
        # and inherit the id from a Title model when the header has none.
        def header(attributes)
          raw = attributes.fetch(:header)
          title = raw[:title]
          id = raw[:id]
          id = title.id if title.is_a?(Model::Title) && title.id && !id
          id = id.to_s unless id.nil?
          id = nil if id&.empty?

          { id:, title:, author: raw[:author], revision: raw[:revision] }
        end

        # Paragraph: raw `lines` become TextElements (same-line joins and
        # inline arrays are normalised by Transformer.lines_to_text_elements).
        def paragraph(attributes)
          raw = attributes.fetch(:paragraph)
          {
            content: Transformer.lines_to_text_elements(raw[:lines]),
            id: raw[:id],
            attributes: raw[:attribute_list],
            title: raw[:title]
          }
        end

        # List item: lines become TextElements (or the bare text), and a
        # raw `nested` array is wrapped into the list type its first
        # marker implies.
        def list_item(attributes)
          raw = attributes.fetch(:list_item)
          lines = raw[:lines]
          content = lines ? Transformer.lines_to_text_elements(lines) : raw[:text].to_s

          { content:, id: raw[:id], marker: raw[:marker], attached: raw[:attached],
            nested: nest_list_items(raw[:nested]), line_break: raw[:line_break] }
        end

        def nest_list_items(nested)
          return nested unless nested.is_a?(Array) && nested.any?

          if nested.all?(Model::List::Core)
            nested.first
          elsif nested.all?(Model::List::Item)
            ordered = nested.first.marker.to_s.lstrip.start_with?('.', '1', 'a', 'A', 'i', 'I')
            (ordered ? Model::List::Ordered : Model::List::Unordered).new(items: nested)
          else
            nested
          end
        end

        # `list:` wrapper node: the inner list passes through.
        def list(attributes)
          attributes.fetch(:list)
        end

        # Definition-list term: flatten to `{text:, id:, delimiter:}`.
        def dlist_term(attributes)
          term = attributes.fetch(:term)
          delimiter = attributes.fetch(:delimiter).to_s
          case term
          when Hash
            text = term[:text]
            text = text.content.to_s if text.is_a?(Model::TextElement)
            { text: text.to_s, id: term[:id]&.to_s, delimiter: }
          when Model::TextElement
            { text: term.content.to_s, id: term.id, delimiter: }
          else
            { text: term.to_s, id: nil, delimiter: }
          end
        end

        # Definition-list item: dd lines split on hard breaks, terms and
        # the item's id/delimiter taken from the flattened term hashes.
        def definition_list_item(attributes)
          raw = attributes.fetch(:item)
          data = raw.is_a?(Hash) ? raw : { terms: Array(raw), lines: [] }
          contents = Transformer.lines_to_text_elements(Transformer.split_lines_on_hard_break(data[:lines] || []))
          id = nil
          delimiter = '::'
          terms = Array(data[:terms]).map do |term|
            next term.to_s unless term.is_a?(Hash)

            id ||= term[:id].to_s if term[:id]
            delimiter = term[:delimiter].to_s if term[:delimiter]
            term[:text].to_s
          end

          { terms:, contents:, id:, delimiter:, attached: Array(data[:attached]) }
        end

        def definition_list(attributes)
          tree = DefinitionListTree.build_dlist_tree(attributes.fetch(:items))
          tree.attrs = attributes[:attrs] if attributes[:attrs]
          tree
        end
      end

      HEADER = Binding.new(
        keys: [:header],
        model: -> { Model::Header },
        captures: { header: :header },
        defaults: {},
        via: Hooks.method(:header)
      )

      PARAGRAPH = Binding.new(
        keys: [:paragraph],
        model: -> { Model::Paragraph },
        captures: { paragraph: :paragraph },
        defaults: {},
        via: Hooks.method(:paragraph)
      )

      AUTHOR = Binding.new(
        keys: %i[first_name last_name email],
        model: -> { Model::Author },
        captures: { first_name: :first_name, last_name: :last_name, email: :email },
        defaults: { middle_name: nil }
      )

      REVISION = Binding.new(
        keys: %i[number date remark],
        model: -> { Model::Revision },
        captures: { number: :number, date: :date, remark: :remark },
        defaults: {}
      )

      LIST_ITEM = Binding.new(
        keys: [:list_item], model: -> { Model::List::Item }, captures: { list_item: :list_item },
        defaults: {}, via: Hooks.method(:list_item)
      )

      LIST = Binding.new(
        keys: [:list], model: nil, captures: { list: :list }, defaults: {}, via: Hooks.method(:list)
      )

      UNORDERED = Binding.new(
        keys: [:unordered], model: -> { Model::List::Unordered }, captures: { items: :unordered }, defaults: {}
      )

      UNORDERED_ATTRS = Binding.new(
        keys: %i[attribute_list unordered], model: -> { Model::List::Unordered },
        captures: { items: :unordered, attrs: :attribute_list }, defaults: {}
      )

      ORDERED = Binding.new(
        keys: [:ordered], model: -> { Model::List::Ordered }, captures: { items: :ordered }, defaults: {}
      )

      ORDERED_ATTRS = Binding.new(
        keys: %i[attribute_list ordered], model: -> { Model::List::Ordered },
        captures: { items: :ordered, attrs: :attribute_list }, defaults: {}
      )

      DLIST_TERM = Binding.new(
        keys: %i[dlist_term delimiter], model: nil, captures: { term: :dlist_term, delimiter: :delimiter },
        defaults: {}, via: Hooks.method(:dlist_term)
      )

      DLIST_ITEM = Binding.new(
        keys: [:definition_list_item], model: -> { Model::List::DefinitionItem },
        captures: { item: :definition_list_item }, defaults: {}, via: Hooks.method(:definition_list_item)
      )

      DLIST = Binding.new(
        keys: [:definition_list], model: nil, captures: { items: :definition_list }, defaults: {},
        via: Hooks.method(:definition_list)
      )

      DLIST_ATTRS = Binding.new(
        keys: %i[attribute_list definition_list], model: nil,
        captures: { items: :definition_list, attrs: :attribute_list }, defaults: {},
        via: Hooks.method(:definition_list)
      )

      # Rules bound so far, in migration order (header -> paragraphs ->
      # lists -> inline).
      ALL = [HEADER, AUTHOR, REVISION, PARAGRAPH,
             LIST_ITEM, LIST, UNORDERED, UNORDERED_ATTRS, ORDERED, ORDERED_ATTRS,
             DLIST_TERM, DLIST_ITEM, DLIST, DLIST_ATTRS].freeze

      class << self
        # @return [Coradoc::BindingInflater] the inflater for the bound rules
        def inflater
          @inflater ||= Coradoc::BindingInflater.new(bindings: ALL)
        end
      end
    end
  end
end
