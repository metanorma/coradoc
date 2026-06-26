# frozen_string_literal: true

module Coradoc
  # Post-parse link/xref rewriting.
  #
  # Consumers that need to canonicalize link and xref targets (snake→kebab,
  # strip +.adoc+, redirect maps, dialect translation) get a single
  # immutable entry point: +Coradoc.rewrite_links(doc, rewriter:, &)+.
  # The visitor walks the parsed CoreModel, invokes the supplied rewriter
  # for every link/xref target, and returns a NEW document. Verbatim
  # blocks (source, listing, literal, pass, stem) are skipped entirely —
  # coradoc owns the parse and guarantees those bodies never reach the
  # rewriter, removing the "track parser state to avoid verbatim bodies"
  # footgun that plagues regex-based rewriting.
  #
  # Two-step API mirrors +Coradoc.resolve_includes+: parse produces the
  # document, rewrite is a separate explicit step the caller controls.
  module LinkRewriter
    autoload :Identity, "#{__dir__}/link_rewriter/identity"
    autoload :Visitor, "#{__dir__}/link_rewriter/visitor"

    class << self
      # Rewrite every link/xref target in +doc+.
      #
      # +rewriter+ responds to +#call(target:, kind:, context:)+ and returns
      # the new target String. If a block is given it is used as the
      # rewriter. Omitting both falls back to {Identity} (no-op) — useful
      # for "give me a structurally identical copy" cases.
      #
      # Returns a NEW document; the input is never mutated.
      def rewrite(doc, rewriter: nil, &block)
        callable = rewriter || block || Identity.new
        Visitor.new(callable).visit_document(doc)
      end
    end
  end
end
