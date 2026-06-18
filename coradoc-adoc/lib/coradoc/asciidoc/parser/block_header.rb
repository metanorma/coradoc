# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Parser
      # Single Responsibility: parse the optional header that precedes a block.
      #
      # Encapsulates the canonical AsciiDoc block-header grammar in one place
      # (DRY, MECE, single source of truth). Before this module existed, every
      # block-like rule (block, table, section, paragraph, block_image) inlined
      # its own header rule with subtly different slot orderings — and several
      # of them captured the same Parslet key more than once in a single
      # sequence, which triggered Parslet's "Duplicate subtrees while merging
      # result" warning and silently discarded one of the captured values.
      #
      # Canonical header shape, each component at most once:
      #
      #   block_title? >> element_id? >> attribute_blocks?
      #
      # `attribute_blocks` accepts one or more consecutive `[...]` attribute
      # lists, captured as a Parslet sequence under the :attribute_list key.
      # Real-world AsciiDoc often stacks attribute lists before a block:
      #
      #   [role=quote]
      #   [source, ruby]
      #   ----
      #   code
      #   ----
      #
      # Capturing the sequence (rather than one slot per `[...]`) preserves
      # every attribute and lets the transformer merge them into a single
      # Coradoc::AsciiDoc::Model::AttributeList downstream.
      module BlockHeader
        # Canonical block header rule. Single canonical order; each of title,
        # id, and attribute_blocks is optional and matched at most once.
        # @return [Parslet::Atoms::Base]
        def block_header
          block_title.maybe >>
            element_id.maybe >>
            attribute_blocks.maybe
        end

        # One or more consecutive attribute_list + newline sequences, captured
        # as a Parslet sequence under :attribute_list. When multiple `[...]`
        # blocks precede a delimiter, all of them reach the transformer; when
        # only one appears, the sequence has a single element and the existing
        # transformer rule handles it the same way as before.
        # @return [Parslet::Atoms::Base]
        def attribute_blocks
          (attribute_list >> newline).repeat(1).as(:attribute_list)
        end
      end
    end
  end
end
