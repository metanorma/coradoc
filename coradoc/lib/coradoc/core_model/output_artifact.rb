# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Output-side state object for host-system emitters (VitePress, Hugo,
    # Astro, plain ERB, etc.).
    #
    # coradoc's source side has +IncludeResolver::Filesystem+ to resolve
    # include targets without coupling to a storage layer. The output side
    # has no analogous state object — until now. +OutputArtifact+ captures
    # the three pieces of state coradoc genuinely needs to hand to a
    # downstream emitter:
    #
    # - +output_key+ — site-relative key (e.g. "author/iso/ref/foo")
    # - +frontmatter_block+ — parsed YAML frontmatter (may be empty)
    # - +core_document+ — the canonical CoreModel document
    #
    # The consumer takes these and renders whatever wrapper it needs in
    # its host system's native template language. coradoc does not know
    # about VitePress, ERB, or Liquid. Symmetric with the source side:
    # minimal protocol object, not an engine.
    #
    # A mirror-tree document is deliberately NOT bundled here. coradoc
    # core has no runtime dependency on coradoc-mirror; consumers that
    # target the mirror JSON pipeline pair an +OutputArtifact+ with a
    # separately-computed +Coradoc::Mirror.transform(core)+ result.
    class OutputArtifact < Base
      # @!attribute output_key
      #   @return [String, nil] site-relative key with no leading slash
      #     and no trailing extension. SSGs map this to their URL space.
      attribute :output_key, :string

      # @!attribute frontmatter_block
      #   @return [FrontmatterBlock, nil] parsed YAML frontmatter
      attribute :frontmatter_block, FrontmatterBlock

      # @!attribute core_document
      #   @return [DocumentElement, nil] canonical CoreModel document
      attribute :core_document, DocumentElement

      private

      def comparable_attributes
        %i[output_key frontmatter_block core_document]
      end
    end
  end
end
