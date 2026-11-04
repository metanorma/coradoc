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
      autoload :StructureHooks, "#{__dir__}/bindings/structure_hooks"

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

        # Inline formatting (bold, italic, highlight, monospace): the
        # constrained/unconstrained flag arrives as a binding default.
        def formatting(attributes)
          { content: Transformer.extract_inline_content(attributes.fetch(:subtree)),
            unconstrained: attributes.fetch(:unconstrained) }
        end

        def span(attributes)
          raw = attributes.fetch(:span)
          { text: raw[:text], unconstrained: attributes.fetch(:unconstrained), attributes: raw[:attribute_list] }
        end

        def script(attributes)
          { content: Transformer.extract_simple_inline_content(attributes.fetch(:script)) }
        end

        def link(attributes)
          raw = attributes.fetch(:link)
          { path: raw[:path].to_s, name: raw[:text]&.to_s }
        end

        def cross_reference(attributes)
          raw = attributes.fetch(:xref)
          { href: raw[:href].to_s, args: raw[:text] ? [raw[:text].to_s] : [] }
        end

        def inline_image(attributes)
          raw = attributes.fetch(:inline_image)
          promoted, residual = Model::Image::AttributeExtractor.call(
            Transformer::AttributeListNormalizer.coerce(raw[:attribute_list]), Model::Image::InlineImage
          )
          { src: raw[:path], attributes: residual, **promoted }
        end

        # Both passthrough forms carry an opaque payload; `form` records the
        # syntax so the serializer can round-trip it.
        def passthrough(attributes)
          { content: attributes.fetch(:passthrough)[:raw].to_s, form: 'triple' }
        end

        # Typographic quotes collapse to the single Unicode character at
        # parse time (shared TypographicQuotes table).
        def typographic_quote(attributes)
          { content: Coradoc::AsciiDoc::TypographicQuotes.char_for(attributes.fetch(:pattern)) }
        end

        # Footnote text arrives as a string or (empty reference) a sequence.
        def footnote(attributes)
          raw = attributes.fetch(:footnote)
          text = raw.is_a?(Array) ? raw.map(&:to_s).join : raw.to_s
          attributes.key?(:id) ? { text:, id: attributes[:id].to_s } : { text: }
        end

        def stem(attributes)
          raw = attributes.fetch(:stem)
          { type: raw[:stem_type], content: raw[:content] }
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

      # Inline formatting variants sharing one rule shape: constrained and
      # unconstrained forms of the same model class. `span` carries
      # `text:` + `attributes:` rather than `content:`, so it is bound apart.
      FORMATTING_VARIANTS = [
        %i[bold Bold], %i[italic Italic], %i[highlight Highlight], %i[monospace Monospace]
      ].freeze

      FORMATTING = FORMATTING_VARIANTS.flat_map do |prefix, class_name|
        [[:"#{prefix}_constrained", false], [:"#{prefix}_unconstrained", true]].map do |key, unconstrained|
          Binding.new(keys: [key], model: -> { Model::Inline.const_get(class_name) }, captures: { subtree: key },
                      defaults: { unconstrained: }, via: Hooks.method(:formatting))
        end
      end.freeze

      SPAN = [[:span_constrained, false], [:span_unconstrained, true]].map do |key, unconstrained|
        Binding.new(keys: [key], model: -> { Model::Inline::Span }, captures: { span: key },
                    defaults: { unconstrained: }, via: Hooks.method(:span))
      end.freeze

      SUPERSCRIPT = Binding.new(keys: [:superscript], model: -> { Model::Inline::Superscript },
                                captures: { script: :superscript }, defaults: {}, via: Hooks.method(:script))

      SUBSCRIPT = Binding.new(keys: [:subscript], model: -> { Model::Inline::Subscript },
                              captures: { script: :subscript }, defaults: {}, via: Hooks.method(:script))

      LINK = Binding.new(keys: [:link], model: -> { Model::Inline::Link }, captures: { link: :link },
                         defaults: {}, via: Hooks.method(:link))

      CROSS_REFERENCE = Binding.new(keys: [:cross_reference], model: -> { Model::Inline::CrossReference },
                                    captures: { xref: :cross_reference }, defaults: {},
                                    via: Hooks.method(:cross_reference))

      INLINE_IMAGE = Binding.new(keys: [:inline_image], model: -> { Model::Image::InlineImage },
                                 captures: { inline_image: :inline_image }, defaults: {},
                                 via: Hooks.method(:inline_image))

      PASSTHROUGH = Binding.new(keys: [:inline_passthrough], model: -> { Model::Inline::Passthrough },
                                captures: { passthrough: :inline_passthrough }, defaults: {},
                                via: Hooks.method(:passthrough))

      ATTRIBUTE_REFERENCE = Binding.new(keys: [:attribute_reference], model: -> { Model::Inline::AttributeReference },
                                        captures: { name: :attribute_reference }, defaults: {})

      TYPOGRAPHIC_QUOTE = Binding.new(keys: [:typographic_quote], model: -> { Model::TextElement },
                                      captures: { pattern: :typographic_quote }, defaults: {},
                                      via: Hooks.method(:typographic_quote))

      HARD_LINE_BREAK = Binding.new(keys: [:hard_line_break], model: -> { Model::Inline::HardLineBreak },
                                    captures: {}, defaults: {})

      TERM = Binding.new(keys: %i[term_type term], model: -> { Model::Term },
                         captures: { term: :term, type: :term_type }, defaults: { lang: :en })

      FOOTNOTE = Binding.new(keys: [:footnote], model: -> { Model::Inline::Footnote },
                             captures: { footnote: :footnote }, defaults: {}, via: Hooks.method(:footnote))

      FOOTNOTE_ID = Binding.new(keys: %i[footnote id], model: -> { Model::Inline::Footnote },
                                captures: { footnote: :footnote, id: :id }, defaults: {},
                                via: Hooks.method(:footnote))

      STEM = Binding.new(keys: [:stem], model: -> { Model::Inline::Stem }, captures: { stem: :stem },
                         defaults: {}, via: Hooks.method(:stem))

      INLINE = [LINK, CROSS_REFERENCE, INLINE_IMAGE, PASSTHROUGH, ATTRIBUTE_REFERENCE, TYPOGRAPHIC_QUOTE,
                HARD_LINE_BREAK, TERM, FOOTNOTE, FOOTNOTE_ID, *FORMATTING, *SPAN,
                SUPERSCRIPT, SUBSCRIPT, STEM].freeze

      # Text, blocks, tables, sections and attributes: the rest of the
      # grammar. Rules the parser never emits (example, audio, video,
      # reviewer note, glossaries, bibliography entry, text_string, the
      # id-bearing text variants, the named title) have no binding; the
      # differential spec guards that the corpus never produces them.
      def self.bind(keys, model, captures = {}, via: nil, defaults: {})
        Binding.new(keys:, model: model && -> { Model.const_get(model) }, captures:, defaults:, via:)
      end

      TEXT = [
        bind(%i[text], 'TextElement', { text: :text }, via: StructureHooks.method(:text)),
        bind(%i[line_break text], 'TextElement', { text: :text, line_break: :line_break },
             via: StructureHooks.method(:text_with_break)),
        bind(%i[line_break], 'LineBreak', { line_break: :line_break }),
        bind(%i[unparsed], nil, { text: :unparsed }, via: StructureHooks.method(:unparsed))
      ].freeze

      BLOCK = [
        bind(%i[block], nil, { block: :block }, via: StructureHooks.method(:block)),
        bind(%i[admonition_type content], 'Admonition', { type: :admonition_type, content: :content },
             via: StructureHooks.method(:admonition)),
        bind(%i[block_image], 'Image::BlockImage', { block_image: :block_image },
             via: StructureHooks.method(:block_image))
      ].freeze

      STRUCTURE = [
        bind(%i[cell_format text], nil, { format: :cell_format, text: :text }, via: StructureHooks.method(:table_cell)),
        bind(%i[cell], nil, { cell: :cell }, via: StructureHooks.unwrap(:cell)),
        bind(%i[row], nil, { row: :row }, via: StructureHooks.unwrap(:row)),
        bind(%i[cells], 'TableRow', { columns: :cells }),
        bind(%i[table], nil, { table: :table }, via: StructureHooks.method(:table)),
        bind(%i[level line_break text], 'Title', { level: :level, text: :text, line_break: :line_break },
             via: StructureHooks.method(:title)),
        bind(%i[section], nil, { section: :section }, via: StructureHooks.method(:section)),
        bind(%i[document], nil, { document: :document }, via: StructureHooks.method(:document))
      ].freeze

      MISC = [
        bind(%i[comment_line], nil, { comment_line: :comment_line },
             via: StructureHooks.method(:comment_line)),
        bind(%i[comment_block], 'CommentBlock', { comment_block: :comment_block },
             via: StructureHooks.method(:comment_block)),
        bind(%i[page_break], 'Break::PageBreak'),
        bind(%i[tag], 'Tag', { tag: :tag }, via: StructureHooks.method(:tag)),
        bind(%i[named], 'Attribute', { named: :named }, via: StructureHooks.method(:named_attribute)),
        bind(%i[attribute_array], nil, { attribute_array: :attribute_array },
             via: StructureHooks.method(:attribute_list)),
        bind(%i[key value line_break], 'Attribute', { key: :key, value: :value, line_break: :line_break },
             via: StructureHooks.method(:attribute)),
        bind(%i[key value], 'Attribute', { key: :key, value: :value }, via: StructureHooks.method(:attribute)),
        bind(%i[document_attributes], 'DocumentAttributes', { data: :document_attributes }),
        bind(%i[include], 'Include', { include: :include }, via: StructureHooks.method(:include))
      ].freeze

      # Every grammar rule the parser emits is bound; the rule modules are retired.
      ALL = [HEADER, AUTHOR, REVISION, PARAGRAPH,
             LIST_ITEM, LIST, UNORDERED, UNORDERED_ATTRS, ORDERED, ORDERED_ATTRS,
             DLIST_TERM, DLIST_ITEM, DLIST, DLIST_ATTRS, *INLINE,
             *TEXT, *BLOCK, *STRUCTURE, *MISC].freeze

      class << self
        # @return [Coradoc::BindingInflater] the inflater for the bound rules
        def inflater
          @inflater ||= Coradoc::BindingInflater.new(bindings: ALL)
        end
      end
    end
  end
end
