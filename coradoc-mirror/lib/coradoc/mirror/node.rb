# frozen_string_literal: true

require 'lutaml/model'
require_relative 'mark'

module Coradoc
  module Mirror
    # ProseMirror-compatible document node.
    #
    # Wire format:
    #
    #   { "type": "paragraph", "attrs": {...}, "content": [...], "marks": [...] }
    #
    # All built-in Node subclasses live below in this file so the
    # TYPE_TO_CLASS registry can see every PM_TYPE at load time. Adding
    # a new node type = adding one subclass (+ optional Attrs sub-model)
    # and letting the registry walker pick it up (OCP).
    #
    # The TYPE_TO_CLASS and POLYMORPHIC constants are declared up-front
    # (empty) because subclass `key_value` blocks reference them at class
    # load time. The table is populated and frozen after every subclass
    # is defined at the bottom of this file.
    class Node < Lutaml::Model::Serializable
      PM_TYPE = 'node'

      TYPE_TO_CLASS = {}
      POLYMORPHIC = { attribute: 'type', class_map: TYPE_TO_CLASS }.freeze

      attribute :type, :string, default: -> { self.class::PM_TYPE }
      attribute :content, Node, collection: true
      attribute :marks, Mark, collection: true

      key_value do
        map 'type', to: :type, render_default: true
        map 'content', to: :content, polymorphic: POLYMORPHIC
        map 'marks', to: :marks, polymorphic: Mark::POLYMORPHIC
      end

      def text_content
        return '' unless content

        content.select { |c| c.is_a?(Node) }.map(&:text_content).join
      end
    end
  end
end

module Coradoc
  module Mirror
    class Node
      # ── Top-level ──

      class Document < Node
        PM_TYPE = 'doc'

        class Attrs < Lutaml::Model::Serializable
          attribute :title, :string
          attribute :id, :string

          key_value do
            map 'title', to: :title
            map 'id', to: :id
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      # ── Structural containers ──

      class Section < Node
        # JS SECTION_TYPES — all deserialize to Section. The type string
        # is preserved as the type attribute on the instance.
        PM_TYPE = 'section'
        PM_ALIASES = %w[
          clause annex content_section abstract foreword introduction
          acknowledgements terms definitions references
        ].freeze

        class Attrs < Lutaml::Model::Serializable
          attribute :title, :string
          attribute :id, :string
          attribute :level, :integer

          key_value do
            map 'title', to: :title
            map 'id', to: :id
            map 'level', to: :level
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      class Preamble < Node
        PM_TYPE = 'preface'

        key_value do
          map 'type', to: :type, render_default: true
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      class Sections < Node
        PM_TYPE = 'sections'

        key_value do
          map 'type', to: :type, render_default: true
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      class Header < Node
        PM_TYPE = 'floating_title'

        class Attrs < Lutaml::Model::Serializable
          attribute :title, :string
          attribute :level, :integer

          key_value do
            map 'title', to: :title
            map 'level', to: :level
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      # ── Text (special: text at top level, not under attrs) ──

      class Text < Node
        PM_TYPE = 'text'

        attribute :text, :string

        key_value do
          map 'type', to: :type, render_default: true
          map 'text', to: :text
          map 'marks', to: :marks, polymorphic: Mark::POLYMORPHIC
        end

        def text_content
          text.to_s
        end
      end

      # Raw inline passthrough — content the source format marked as "do
      # not process, emit verbatim." Distinct from `text` so renderers can
      # skip escaping without sniffing content for `<...>`. AsciiDoc's
      # `+++raw+++` is the canonical producer.
      class RawInline < Node
        PM_TYPE = 'raw_inline'

        attribute :text, :string

        key_value do
          map 'type', to: :type, render_default: true
          map 'text', to: :text
        end

        def text_content
          text.to_s
        end
      end

      # ── Paragraph / block text ──

      class Paragraph < Node
        PM_TYPE = 'paragraph'

        key_value do
          map 'type', to: :type, render_default: true
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
          map 'marks', to: :marks, polymorphic: Mark::POLYMORPHIC
        end
      end

      class CodeBlock < Node
        PM_TYPE = 'sourcecode'

        class Attrs < Lutaml::Model::Serializable
          attribute :language, :string
          attribute :title, :string
          attribute :passthrough, :boolean
          attribute :text, :string

          key_value do
            map 'language', to: :language
            map 'title', to: :title
            map 'passthrough', to: :passthrough
            map 'text', to: :text
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      # Literal block — preformatted text (`....` delimiter). Same shape
      # as CodeBlock but distinguished on the wire so consumers can apply
      # literal-vs-source rendering/styling.
      class LiteralBlock < CodeBlock
        PM_TYPE = 'literal'
      end

      # Pass block — raw passthrough content (`++++` delimiter). Same
      # shape as CodeBlock; flagged via attrs.passthrough = true.
      class PassBlock < CodeBlock
        PM_TYPE = 'pass'
      end

      # STEM block — mathematical/scientific markup (`[stem|latexmath|
      # asciimath]\n++++`). Carries a +language+ attr ('latex' default,
      # 'asciimath' alternative).
      class StemBlock < CodeBlock
        PM_TYPE = 'stem'
      end

      class Blockquote < Node
        PM_TYPE = 'quote'

        class Attrs < Lutaml::Model::Serializable
          attribute :attribution, :string

          key_value do
            map 'attribution', to: :attribution
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      class Example < Node
        PM_TYPE = 'example'

        class Attrs < Lutaml::Model::Serializable
          attribute :title, :string
          attribute :id, :string

          key_value do
            map 'title', to: :title
            map 'id', to: :id
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      class Sidebar < Node
        PM_TYPE = 'sidebar'

        class Attrs < Lutaml::Model::Serializable
          attribute :title, :string
          attribute :id, :string

          key_value do
            map 'title', to: :title
            map 'id', to: :id
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      class OpenBlock < Node
        PM_TYPE = 'open_block'

        key_value do
          map 'type', to: :type, render_default: true
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      class Verse < Node
        PM_TYPE = 'verse'

        class Attrs < Lutaml::Model::Serializable
          attribute :attribution, :string

          key_value do
            map 'attribution', to: :attribution
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      class HorizontalRule < Node
        PM_TYPE = 'horizontal_rule'
      end

      class ThematicBreak < Node
        PM_TYPE = 'thematic_break'
      end

      class SoftBreak < Node
        PM_TYPE = 'soft_break'
      end

      # ── Admonition (NOTE, TIP, WARNING, CAUTION, IMPORTANT) ──
      #
      # The Ruby attribute name is `admonition_type` (kept distinct from
      # Node's built-in `type` discriminator). The wire attribute name is
      # `type` per the @metanorma/mirror JS contract. The rename happens
      # via a `map` declaration — no hand-rolled to_h/from_h.

      class Admonition < Node
        PM_TYPE = 'admonition'

        class Attrs < Lutaml::Model::Serializable
          attribute :admonition_type, :string
          attribute :title, :string
          attribute :label, :string
          attribute :id, :string

          key_value do
            map 'type', to: :admonition_type # RENAME: Ruby ≠ wire
            map 'title', to: :title
            map 'label', to: :label
            map 'id', to: :id
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      # ── Lists ──

      class BulletList < Node
        PM_TYPE = 'bullet_list'

        class Attrs < Lutaml::Model::Serializable
          attribute :id, :string
          attribute :start, :integer

          key_value do
            map 'id', to: :id
            map 'start', to: :start
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      class OrderedList < Node
        PM_TYPE = 'ordered_list'

        class Attrs < Lutaml::Model::Serializable
          attribute :id, :string
          attribute :start, :integer

          key_value do
            map 'id', to: :id
            map 'start', to: :start
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      class ListItem < Node
        PM_TYPE = 'list_item'

        class Attrs < Lutaml::Model::Serializable
          attribute :id, :string

          key_value do
            map 'id', to: :id
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
          map 'marks', to: :marks, polymorphic: Mark::POLYMORPHIC
        end
      end

      class DefinitionList < Node
        PM_TYPE = 'dl'

        class Attrs < Lutaml::Model::Serializable
          attribute :id, :string

          key_value do
            map 'id', to: :id
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      class DefinitionTerm < Node
        PM_TYPE = 'dt'

        key_value do
          map 'type', to: :type, render_default: true
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
          map 'marks', to: :marks, polymorphic: Mark::POLYMORPHIC
        end
      end

      class DefinitionDescription < Node
        PM_TYPE = 'dd'

        key_value do
          map 'type', to: :type, render_default: true
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
          map 'marks', to: :marks, polymorphic: Mark::POLYMORPHIC
        end
      end

      # ── Media ──

      class Image < Node
        PM_TYPE = 'image'

        class Attrs < Lutaml::Model::Serializable
          attribute :src, :string
          attribute :alt, :string
          attribute :title, :string
          attribute :caption, :string
          attribute :width, :string
          attribute :height, :string
          attribute :inline, :boolean

          key_value do
            map 'src', to: :src
            map 'alt', to: :alt
            map 'title', to: :title
            map 'caption', to: :caption
            map 'width', to: :width
            map 'height', to: :height
            map 'inline', to: :inline
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      # JS @metanorma/mirror figure: wraps Image + optional Caption.
      class Figure < Node
        PM_TYPE = 'figure'

        class Attrs < Lutaml::Model::Serializable
          attribute :id, :string
          attribute :title, :string

          key_value do
            map 'id', to: :id
            map 'title', to: :title
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      class Caption < Node
        PM_TYPE = 'caption'

        key_value do
          map 'type', to: :type, render_default: true
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
          map 'marks', to: :marks, polymorphic: Mark::POLYMORPHIC
        end
      end

      # Include directive node — a text-graph edge pointing at another file.
      # Graph mode emits this; flat mode (ResolveIncludes) replaces it with
      # the included subtree before serialization.
      class Include < Node
        PM_TYPE = 'include'

        class Attrs < Lutaml::Model::Serializable
          attribute :target, :string
          attribute :tags, :string, collection: true
          attribute :lines, :string
          attribute :leveloffset, :string
          attribute :indent, :integer
          attribute :file_encoding, :string
          attribute :raw_options, :string

          key_value do
            map 'target', to: :target
            map 'tags', to: :tags
            map 'lines', to: :lines
            map 'leveloffset', to: :leveloffset
            map 'indent', to: :indent
            map 'encoding', to: :file_encoding
            map 'raw_options', to: :raw_options
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
        end
      end

      # ── Tables ──

      class Table < Node
        PM_TYPE = 'table'

        class Attrs < Lutaml::Model::Serializable
          attribute :title, :string
          attribute :id, :string
          attribute :width, :string

          key_value do
            map 'title', to: :title
            map 'id', to: :id
            map 'width', to: :width
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      class TableHead < Node
        PM_TYPE = 'table_head'

        key_value do
          map 'type', to: :type, render_default: true
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      class TableBody < Node
        PM_TYPE = 'table_body'

        key_value do
          map 'type', to: :type, render_default: true
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      class TableRow < Node
        PM_TYPE = 'table_row'

        key_value do
          map 'type', to: :type, render_default: true
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      class TableCell < Node
        PM_TYPE = 'table_cell'

        class Attrs < Lutaml::Model::Serializable
          attribute :colspan, :integer
          attribute :rowspan, :integer
          attribute :alignment, :string
          attribute :header, :boolean

          key_value do
            map 'colspan', to: :colspan
            map 'rowspan', to: :rowspan
            map 'alignment', to: :alignment
            map 'header', to: :header
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
          map 'marks', to: :marks, polymorphic: Mark::POLYMORPHIC
        end
      end

      # ── Bibliography ──

      class Bibliography < Node
        PM_TYPE = 'bibliography'

        class Attrs < Lutaml::Model::Serializable
          attribute :title, :string
          attribute :id, :string
          attribute :level, :integer

          key_value do
            map 'title', to: :title
            map 'id', to: :id
            map 'level', to: :level
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      class BibliographyEntry < Node
        PM_TYPE = 'biblio_entry'

        class Attrs < Lutaml::Model::Serializable
          attribute :anchor_name, :string
          attribute :document_id, :string
          attribute :url, :string

          key_value do
            map 'anchor_name', to: :anchor_name
            map 'document_id', to: :document_id
            map 'url', to: :url
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      # ── Footnotes ──

      class Footnotes < Node
        PM_TYPE = 'footnotes'

        key_value do
          map 'type', to: :type, render_default: true
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      class FootnoteMarker < Node
        PM_TYPE = 'footnote_marker'

        class Attrs < Lutaml::Model::Serializable
          attribute :id, :string
          attribute :ref_id, :string
          attribute :number, :integer

          key_value do
            map 'id', to: :id
            map 'ref_id', to: :ref_id
            map 'number', to: :number
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
        end
      end

      class FootnoteEntry < Node
        PM_TYPE = 'footnote_entry'

        class Attrs < Lutaml::Model::Serializable
          attribute :id, :string
          attribute :ref_id, :string
          attribute :number, :integer

          key_value do
            map 'id', to: :id
            map 'ref_id', to: :ref_id
            map 'number', to: :number
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      # ── TOC ──

      class Toc < Node
        PM_TYPE = 'toc'

        class Attrs < Lutaml::Model::Serializable
          attribute :title, :string

          key_value do
            map 'title', to: :title
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      class TocEntry < Node
        PM_TYPE = 'toc_entry'

        class Attrs < Lutaml::Model::Serializable
          attribute :id, :string
          attribute :title, :string
          attribute :level, :integer

          key_value do
            map 'id', to: :id
            map 'title', to: :title
            map 'level', to: :level
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      # ── Generic (catch-all) ──

      class GenericBlock < Node
        PM_TYPE = 'generic_block'

        class Attrs < Lutaml::Model::Serializable
          attribute :semantic_type, :string
          attribute :title, :string
          attribute :id, :string

          key_value do
            map 'semantic_type', to: :semantic_type
            map 'title', to: :title
            map 'id', to: :id
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
          map 'content', to: :content, polymorphic: Node::POLYMORPHIC
        end
      end

      # ── Frontmatter (typed tree — no hashes) ──

      class FrontmatterValue < Lutaml::Model::Serializable; end

      class FrontmatterEntry < Lutaml::Model::Serializable
        attribute :key, :string
        attribute :value, FrontmatterValue

        key_value do
          map 'key', to: :key, render_default: true
          map 'value', to: :value
        end
      end

      class FrontmatterValue
        attribute :value_type, :string
        attribute :string_value, :string
        attribute :integer_value, :integer
        attribute :float_value, :float
        attribute :boolean_value, :boolean
        attribute :date_value, :date
        attribute :datetime_value, :date_time
        attribute :symbol_value, :string
        attribute :items, FrontmatterValue, collection: true
        attribute :entries, FrontmatterEntry, collection: true

        key_value do
          map 'value_type', to: :value_type, render_default: true
          map 'string_value', to: :string_value
          map 'integer_value', to: :integer_value
          map 'float_value', to: :float_value
          map 'boolean_value', to: :boolean_value
          map 'date_value', to: :date_value
          map 'datetime_value', to: :datetime_value
          map 'symbol_value', to: :symbol_value
          map 'items', to: :items
          map 'entries', to: :entries
        end
      end

      class Frontmatter < Node
        PM_TYPE = 'frontmatter'

        class Attrs < Lutaml::Model::Serializable
          attribute :schema, :string
          attribute :entries, FrontmatterEntry, collection: true

          key_value do
            map 'schema', to: :schema
            map 'entries', to: :entries
          end
        end

        attribute :attrs, Attrs

        key_value do
          map 'type', to: :type, render_default: true
          map 'attrs', to: :attrs
        end
      end
    end
  end
end

module Coradoc
  module Mirror
    class Node
      # Populate the polymorphic class map now that every subclass is
      # defined. Maps each PM_TYPE wire string to its Ruby class name.
      # Section's PM_ALIASES are added on top so all JS SECTION_TYPES
      # route to Section on reverse parse.
      Node.constants.each do |name|
        k = Node.const_get(name)
        next unless k.is_a?(Class) && k < Node && k::PM_TYPE != 'node'

        TYPE_TO_CLASS[k::PM_TYPE] = k.name
        Array(k::PM_ALIASES).each { |a| TYPE_TO_CLASS[a] = k.name } if k.const_defined?(:PM_ALIASES, false)
      end
      TYPE_TO_CLASS.freeze
    end
  end
end
