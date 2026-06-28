# frozen_string_literal: true

module Coradoc
  module Mirror
    # OCP-compliant registry for Mirror node → CoreModel transformation.
    #
    # Single source of truth: the TYPE_TO_FILE table below maps every
    # Mirror wire type string (and its aliases) to the file that
    # implements its builder. Two things derive from this one table:
    #
    #   1. autoload declarations — one per unique file, so builders
    #      load lazily on first lookup (no 47-file eager load at boot).
    #   2. lookup() — type → file → const_get, which triggers autoload.
    #
    # Adding a new built-in builder is purely additive:
    #
    #   1. Add `'<wire_type>' => '<file_basename>'` to TYPE_TO_FILE.
    #   2. Create `reverse_builder/<file_basename>.rb` defining
    #      `class <CamelizedName> < Base; def build(node); ...; end; end`.
    #
    # No edits to this file beyond the table — autoload and lookup
    # adapt automatically. Mirror-level mark dispatch lives in
    # MarkReverseBuilder (mark_reverse_builder.rb).
    #
    # Third-party / runtime builders can still register via
    # `ReverseBuilder.register(type, klass)`; they take precedence over
    # built-in autoload entries.
    module ReverseBuilder
      autoload :Base, "#{__dir__}/reverse_builder/base"

      # Wire type string → file basename under reverse_builder/.
      # Aliases (e.g. 'clause' and 'annex' both route to section) are
      # expressed by mapping multiple type strings to the same file.
      TYPE_TO_FILE = {
        'doc' => 'document',
        'section' => 'section',
        'clause' => 'section',
        'annex' => 'section',
        'content_section' => 'section',
        'abstract' => 'section',
        'foreword' => 'section',
        'introduction' => 'section',
        'acknowledgements' => 'section',
        'terms' => 'section',
        'definitions' => 'section',
        'references' => 'section',
        'sections' => 'sections',
        'preface' => 'preamble',
        'floating_title' => 'header',
        'heading' => 'header',
        'paragraph' => 'paragraph',
        'sourcecode' => 'code_block',
        'literal' => 'literal_block',
        'pass' => 'pass_block',
        'stem' => 'stem_block',
        'quote' => 'blockquote',
        'example' => 'example',
        'sidebar' => 'sidebar',
        'abstract_block' => 'abstract',
        'partintro_block' => 'partintro',
        'open_block' => 'open_block',
        'verse' => 'verse',
        'horizontal_rule' => 'horizontal_rule',
        'thematic_break' => 'horizontal_rule',
        'soft_break' => 'soft_break',
        'hard_break' => 'hard_break',
        'admonition' => 'admonition',
        'bullet_list' => 'bullet_list',
        'ordered_list' => 'ordered_list',
        'list_item' => 'list_item',
        'dl' => 'definition_list',
        'dt' => 'inline_text',
        'dd' => 'inline_text',
        'image' => 'image',
        'figure' => 'figure',
        'caption' => 'caption',
        'include' => 'include',
        'table' => 'table',
        'table_head' => 'table_head',
        'table_body' => 'table_body',
        'table_row' => 'table_row',
        'table_cell' => 'table_cell',
        'bibliography' => 'bibliography',
        'biblio_entry' => 'biblio_entry',
        'footnotes' => 'footnotes',
        'footnote_entry' => 'footnote_entry',
        'footnote_marker' => 'footnote_marker',
        'toc' => 'toc',
        'toc_entry' => 'toc_entry',
        'text' => 'text',
        'raw_inline' => 'raw_inline',
        'frontmatter' => 'frontmatter',
        'generic_block' => 'generic_block'
      }.freeze

      # File basename → Ruby constant name. Derived from the file name
      # using the project-wide snake_case → CamelCase convention
      # (every existing builder follows it). Declared once here so
      # adding a builder that follows convention requires no extra
      # wiring.
      FILE_TO_CLASS = TYPE_TO_FILE.each_value.each_with_object({}) do |file, acc|
        next if acc.key?(file)

        acc[file] = file.split('_').map(&:capitalize).join
      end.freeze

      # Lazy-load each builder. Lookup triggers autoload via const_get.
      FILE_TO_CLASS.each do |file, const_name|
        autoload const_name.to_sym, "#{__dir__}/reverse_builder/#{file}"
      end

      # Runtime registrations from third-party / external builders.
      # Takes precedence over built-in autoload entries so external
      # code can override built-in behaviour (e.g. a custom Paragraph).
      # Not frozen: register() writes here at runtime.
      REGISTRY = {}

      module_function

      def register(type, builder_class)
        REGISTRY[type] = builder_class
      end

      # DSL for subclasses to self-register at load time. Kept for
      # backward compatibility with the existing OCP test pattern that
      # creates synthetic builders via `Class.new(Base) { registers(...) }`.
      # Built-in builders no longer call this — their dispatch is
      # derived from TYPE_TO_FILE.
      def registers(*types)
        types.each { |t| register(t, self) }
      end

      def lookup(type)
        return REGISTRY[type] if REGISTRY.key?(type)

        file = TYPE_TO_FILE[type]
        return nil unless file

        const_get(FILE_TO_CLASS[file])
      end

      def registered_types
        (REGISTRY.keys + TYPE_TO_FILE.keys).uniq
      end
    end
  end
end
