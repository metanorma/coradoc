# frozen_string_literal: true

module Coradoc
  module Markdown
    # PARG bindings for the Markdown block grammar: which raw-tree rules
    # inflate directly to schema-generated model classes through
    # Coradoc::BindingInflater. A rule is bound by its exact capture-key
    # set. Only the stateful rules stay in the residual (Transformer):
    # ALD definitions (they register in the ALD table) and a standalone
    # IAL (it resolves against that table).
    #
    # Every rule except the thematic break takes its attributes from the
    # raw subtree through a named hook (`via:`), because the attribute is
    # computed (heading level from the marker, text joined from lines,
    # list items grouped) rather than copied from a capture.
    #
    # The binding machinery proper (codegen-ed bindings, typed capture
    # assignment) is lutaml-model#1033; these declarations are the data
    # it will back.
    module Bindings
      Binding = Coradoc::BindingInflater::Binding

      # Semantic steps: raw captures in, model attributes out. They reuse
      # the Transformer's text and IAL helpers, so a bound rule and the
      # hand-written one cannot drift on those.
      module Hooks
        module_function

        def transformer
          Coradoc::Markdown::Transformer
        end

        def model(name)
          Schema.generated_class(name)
        end

        # IAL attributes, set only when present (as Transformer does).
        def ial(attrs)
          return {} unless attrs.key?(:ial)

          parsed = transformer.parse_ial_content(attrs[:ial].to_s)
          { id: parsed[:id], classes: parsed[:classes], attributes: parsed[:attributes] }.compact
        end

        def heading(attrs)
          text = attrs.key?(:text) ? transformer.extract_text(attrs[:text]).strip : ''
          { level: transformer.heading_level(attrs[:heading]), text: text, **ial(attrs) }
        end

        def code_block(attrs)
          language = attrs.key?(:info) ? { language: attrs[:info].to_s.strip } : {}
          { **language, code: transformer.extract_code(attrs[:code_block]), **ial(attrs) }
        end

        def block_quote(attrs)
          content = attrs[:block_quote]
          nodes = content.is_a?(Array) ? content : [content]
          text = nodes.map { |node| transformer.transform_element(node) }.compact.map do |child|
            child.is_a?(Base) && child.class.attributes.key?(:text) ? child.text : child.to_s
          end.join("\n")
          { content: text, **ial(attrs) }
        end

        def paragraph(attrs)
          p = attrs[:p]
          { text: transformer.extract_text_from_p(p), children: inline_models(p), **ial(attrs) }
        end

        # A bare line that no other rule claimed is a paragraph.
        def line(attrs)
          { text: attrs[:ln].to_s }
        end

        def list(attrs)
          ordered = attrs.key?(:ol)
          list_attributes(attrs[ordered ? :ol : :ul], ordered: ordered)
        end

        def list_attributes(items, ordered:)
          items = [items] unless items.is_a?(Array)
          { ordered: ordered, items: items.map { |node| list_item(node.is_a?(Hash) ? node[:li] : node) } }
        end

        def list_item(item_node)
          text_parts = []
          children = []
          sublist = nil
          transformer.normalize_list_item_nodes(item_node).each do |node|
            if !node.is_a?(Hash)
              text_parts << node.to_s
            elsif node.key?(:p)
              text_parts << transformer.extract_text_from_p(node[:p])
              children.concat(inline_models(node[:p]))
            elsif node.key?(:ul)
              sublist = model('List').new(**list_attributes(node[:ul], ordered: false))
            elsif node.key?(:ol)
              sublist = model('List').new(**list_attributes(node[:ol], ordered: true))
            end
          end
          item = model('ListItem').new(text: text_parts.join(' ').strip, children: children)
          item.sublist = sublist if sublist
          item
        end

        # The parser yields terms and definitions as a flat sequence;
        # each definition belongs to the term before it.
        def definition_list(attrs)
          entries = []
          Array(attrs[:dl]).each do |node|
            next unless node.is_a?(Hash)

            if node.key?(:def_term)
              entries << [transformer.extract_text(node[:def_term]).strip, []]
            elsif node.key?(:def_content) && entries.any?
              entries.last.last << model('DefinitionItem').new(
                content: transformer.extract_text(node[:def_content]).strip
              )
            end
          end
          { items: entries.map { |text, definitions| model('DefinitionTerm').new(text: text, definitions: definitions) } }
        end

        def table(attrs)
          rows = Array(attrs[:table_body]).map do |node|
            transformer.extract_row_cells(node[:table_body_row][:row]).join(' | ')
          end
          { headers: transformer.extract_row_cells(attrs[:table_header][:row]), rows: rows }
        end

        def footnote(attrs)
          lines = [attrs[:fn_content]]
          lines += Array(attrs[:fn_content_continued]) if attrs[:fn_content_continued]
          content = lines.map { |line| transformer.extract_text(line) }.join("\n")
          { id: attrs[:fn_id].to_s, content: content.strip }
        end

        def abbreviation(attrs)
          { term: attrs[:abbr_term].to_s, definition: attrs[:abbr_def].to_s.strip }
        end

        def footnote_reference(attrs)
          { id: attrs[:fn_ref].to_s }
        end

        # `{extension: {ext_*}}` wraps the same captures the bare form has.
        def extension(attrs)
          node = attrs[:extension] || attrs
          opts = node[:ext_options]
          empty = !opts || (opts.is_a?(Array) && opts.empty?)
          { name: node[:ext_name].to_s,
            options: empty ? {} : transformer.parse_extension_options(opts.to_s),
            content: node[:ext_body]&.to_s }
        end

        def math(attrs)
          { content: transformer.extract_text(attrs[:math_content]), inline: false }
        end

        def strong(attrs)
          { text: transformer.flatten_inline_text(attrs[:strong]) }
        end

        def emphasis(attrs)
          { text: transformer.flatten_inline_text(attrs[:emph]) }
        end

        def code(attrs)
          { text: attrs[:code].to_s }
        end

        def text(attrs)
          { content: attrs[:text].to_s }
        end

        # Inline models for a paragraph's raw lines, each parsed by the
        # InlineParser and inflated through the inline bindings.
        def inline_models(paragraph)
          lines = if paragraph.is_a?(Hash)
                    [paragraph[:ln]]
                  else
                    Array(paragraph).map { |l| l.is_a?(Hash) ? l[:ln] : l }
                  end
          lines.compact.flat_map.with_index do |line, index|
            models = Coradoc::Markdown.parse_inline(line.to_s).flat_map { |node| inline_model(node) }
            index.zero? ? models : [model('Text').new(content: "\n"), *models]
          end
        end

        def inline_model(node)
          Bindings.inline_inflater.inflate(node) do |unbound|
            content = unbound.is_a?(Hash) ? transformer.flatten_inline_text([unbound]) : unbound.to_s
            model('Text').new(content: content)
          end
        end
      end

      # Thematic break: `{hr: true}` -> HorizontalRule(style: '---').
      THEMATIC_BREAK = Binding.new(
        keys: [:hr],
        model: -> { Schema.generated_class('HorizontalRule') },
        captures: {},
        defaults: { style: '---' }
      )

      # One entry per rule: the model, its hook, and the raw captures the
      # node carries. `optional` captures may be absent; `ial` rules may
      # carry a trailing inline attribute list (bound as a second key set).
      DECLARATIONS = [
        { model: 'Heading', via: :heading, raw: %i[heading text], optional: %i[text], ial: true },
        { model: 'CodeBlock', via: :code_block, raw: %i[code_block info], optional: %i[info] },
        { model: 'Blockquote', via: :block_quote, raw: %i[block_quote] },
        { model: 'Paragraph', via: :paragraph, raw: %i[p], ial: true },
        { model: 'Paragraph', via: :line, raw: %i[ln] },
        { model: 'List', via: :list, raw: %i[ul] },
        { model: 'List', via: :list, raw: %i[ol] },
        { model: 'DefinitionList', via: :definition_list, raw: %i[dl] },
        { model: 'Table', via: :table, raw: %i[table_header table_separator table_body], optional: %i[table_body] },
        { model: 'Footnote', via: :footnote, raw: %i[fn_id fn_content fn_content_continued],
          optional: %i[fn_content_continued] },
        { model: 'Abbreviation', via: :abbreviation, raw: %i[abbr_term abbr_def] },
        { model: 'FootnoteReference', via: :footnote_reference, raw: %i[fn_ref] },
        { model: 'Extension', via: :extension, raw: %i[extension] },
        { model: 'Extension', via: :extension, raw: %i[ext_name ext_options ext_body], optional: %i[ext_body] },
        { model: 'Math', via: :math, raw: %i[math_content] },
        { model: 'Text', via: :text, raw: %i[text] }
      ].freeze

      # Inline rules, reached only through a paragraph's raw lines (the
      # block parser never yields them as blocks), so they have their own
      # inflater and a bare `{strong: ...}` block stays unbound.
      INLINE_DECLARATIONS = [
        { model: 'Strong', via: :strong, raw: %i[strong] },
        { model: 'Emphasis', via: :emphasis, raw: %i[emph] },
        { model: 'Code', via: :code, raw: %i[code] },
        { model: 'Text', via: :text, raw: %i[text] }
      ].freeze

      class << self
        # @return [Coradoc::BindingInflater] the inflater for the bound rules
        def inflater
          @inflater ||= Coradoc::BindingInflater.new(bindings: [THEMATIC_BREAK, *declared_bindings(DECLARATIONS)])
        end

        # @return [Coradoc::BindingInflater] the inflater for inline nodes
        def inline_inflater
          @inline_inflater ||= Coradoc::BindingInflater.new(bindings: declared_bindings(INLINE_DECLARATIONS))
        end

        private

        def declared_bindings(declarations)
          declarations.flat_map do |declaration|
            key_sets(declaration).map { |keys| declared_binding(declaration, keys) }
          end
        end

        # Every key set the rule may arrive with: optional captures may
        # be absent, an IAL may trail.
        def key_sets(declaration)
          optional = declaration.fetch(:optional, [])
          required = declaration[:raw] - optional
          sets = (0..optional.size).flat_map { |n| optional.combination(n).map { |picked| required + picked } }
          declaration[:ial] ? sets.flat_map { |keys| [keys, [*keys, :ial]] } : sets
        end

        def declared_binding(declaration, keys)
          name = declaration[:model]
          Binding.new(
            keys: keys,
            model: -> { Schema.generated_class(name) },
            captures: {},
            defaults: {},
            raw: keys.to_h { |key| [key, key] },
            via: Hooks.method(declaration[:via])
          )
        end
      end
    end
  end
end
