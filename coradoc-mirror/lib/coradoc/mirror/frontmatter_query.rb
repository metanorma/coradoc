# frozen_string_literal: true

module Coradoc
  module Mirror
    # Public read-API: extract a flat Ruby Hash from a Mirror document's
    # frontmatter node.
    #
    # Why this exists: site generators (e.g. metanorma.org's convert-adoc.rb)
    # need frontmatter as a plain Hash for templating VitePress/Jekyll
    # frontmatter output. Without this, callers would either (a) re-parse
    # the source YAML — violating FrontmatterBlock::Codec's "single source
    # of truth" rule — or (b) hand-walk the typed FrontmatterEntry /
    # FrontmatterValue tree themselves, duplicating the reverse builder's
    # logic. This module is the single entry point for both problems.
    #
    # Reuses FrontmatterTreeToHash — same translator the reverse builder
    # uses — so the read-path is shared (DRY/MECE).
    module FrontmatterQuery
      module_function

      # @param mirror_doc [Mirror::Node::Document, nil]
      # @return [Hash{String,Object}] flat key→value mapping; empty Hash
      #   if the document has no frontmatter node or no entries
      def to_hash(mirror_doc)
        frontmatter = find_frontmatter(mirror_doc)
        return {} unless frontmatter

        entries = frontmatter.attrs&.entries || []
        FrontmatterTreeToHash.to_hash(entries)
      end

      # @param mirror_doc [Mirror::Node::Document, nil] (see #to_hash)
      # @return [Boolean] true if the document carries a frontmatter node
      #   with at least one entry
      def has_frontmatter?(mirror_doc)
        frontmatter = find_frontmatter(mirror_doc)
        !frontmatter.nil? && !(frontmatter.attrs&.entries || []).empty?
      end

      def find_frontmatter(mirror_doc)
        return nil if mirror_doc.nil?

        content = mirror_doc.content
        return nil unless content

        content.find { |node| node.is_a?(Node) && node.type == 'frontmatter' }
      end
    end
  end
end
