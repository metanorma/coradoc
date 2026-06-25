# frozen_string_literal: true

module Coradoc
  module CoreModel
    # First-class include directive node in the canonical document model.
    #
    # An include directive is a LINK from one document to another file.
    # Parsing preserves these nodes verbatim — no file I/O happens during
    # parse. The result is a text graph: a document referencing other
    # documents via Include edges.
    #
    # Splicing the linked content inline is an explicit, separate step:
    # +Coradoc.resolve_includes(doc, base_dir:)+ walks the tree and
    # replaces each Include node with the parsed content of its target,
    # recursing into the result.
    #
    # This separation lets callers:
    #   - inspect the graph before deciding to flatten
    #   - resolve with different base dirs / resolvers without re-parsing
    #   - treat includes as external links (e.g. when parsing a site)
    #
    # Attributes:
    #   target       String           path or URL as authored
    #   options      IncludeOptions   parsed selectors (tags/lines/leveloffset/indent/encoding)
    #   raw_options  String           original bracket body, preserved for verbatim round-trip
    #   line_break   String           trailing line break, default "\n"
    #
    # The node is block-level: it appears in the +content+ / +children+
    # array of any block container (Document, Section, Paragraph, List
    # item, Table cell, etc.) alongside other block-level nodes.
    class Include < Base
      attribute :target, :string
      attribute :options, Coradoc::CoreModel::IncludeOptions,
                default: -> { Coradoc::CoreModel::IncludeOptions.new }
      attribute :raw_options, :string, default: -> { '' }
      attribute :line_break, :string, default: -> { "\n" }

      def self.semantic_type
        :include
      end
    end
  end
end
