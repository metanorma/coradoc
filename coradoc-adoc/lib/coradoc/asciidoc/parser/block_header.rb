# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Parser
      # Single Responsibility: parse the optional header that precedes a
      # structural element (block or section).
      #
      # Encapsulates the canonical AsciiDoc header grammar in one place
      # (DRY, MECE, single source of truth). Two flavours live here because
      # blocks and sections have different header grammars:
      #
      #   block_header   = block_title? >> element_id? >> attribute_blocks?
      #   section_header =                    element_id? >> attribute_blocks?
      #
      # Asciidoctor does NOT permit `.Title` to apply to a section — sections
      # accept `[role]` attribute lists and `[[id]]` anchors but not block
      # titles. The section's heading IS its title. Mixing the two shapes
      # into one rule caused `section_block` to admit `.Foo` lines that
      # collided with `section_title`'s `:title` capture, triggering
      # Parslet's "Duplicate subtrees while merging result … (keys:
      # [:title])" warning and silently dropping the block title.
      #
      # Before this module existed, every block-like rule inlined its own
      # header rule with subtly different slot orderings — and several
      # captured the same Parslet key more than once in a single sequence,
      # which triggered Parslet's "Duplicate subtrees" warning and silently
      # discarded one of the captured values.
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
        # Canonical block header rule. Includes the block title — every
        # real block (delimited block, table, paragraph, image) accepts
        # an optional `.Title` line before its body. Single canonical
        # order; each of title, id, and attribute_blocks is optional and
        # matched at most once.
        # @return [Parslet::Atoms::Base]
        def block_header
          block_title.maybe >>
            element_id.maybe >>
            attribute_blocks.maybe
        end

        # Section header rule. Asciidoctor does not permit `.Title` on
        # sections — the section heading itself is the title. Sections
        # still accept the same element_id and attribute_blocks slots
        # that blocks do (`[[anchor]]`, `[appendix]`, `[role=x]`, etc.).
        # @return [Parslet::Atoms::Base]
        def section_header
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
