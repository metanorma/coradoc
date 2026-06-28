# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      module ElementTransformers
        # Admonition style registry. Single source of truth for "which
        # positional attribute names map to an admonition block."
        #
        # Built-in AsciiDoc admonition styles are always recognized. Callers
        # can register additional styles (e.g. +DANGER+, +SAFETY+) without
        # modifying dispatch code — the registry is consulted by every
        # block-form transformer that needs to decide between an admonition
        # and the block's native type.
        module AdmonitionStyles
          # Generic `[admonition]` (capitalized as ADMONITION by
          # +canonicalize+) is the spec-defined generic admonition style.
          # It is rarely used directly but exists in the AsciiDoc spec;
          # treating it as a real admonition prevents it from collapsing
          # to an ExampleBlock when applied to a delimited block.
          BUILTIN = %w[note tip warning caution important editor todo admonition].freeze

          @custom = []

          class << self
            # True if +style+ (case-insensitive) is a known admonition style.
            def admonition?(style)
              return false if style.nil?

              name = style.to_s.downcase
              BUILTIN.include?(name) || custom.include?(name)
            end

            # Canonical uppercase form for +style+, or nil if unknown.
            # Single source of truth for the canonical casing used in
            # CoreModel::AnnotationBlock#annotation_type and AsciiDoc
            # round-trip output.
            def canonicalize(style)
              return nil unless admonition?(style)

              style.to_s.upcase
            end

            # All registered style names (BUILTIN + custom), lowercased.
            def all_styles
              (BUILTIN + custom).freeze
            end

            # Register an additional admonition style. Open for extension.
            def register(style)
              name = style.to_s.downcase
              @custom << name unless @custom.include?(name) || BUILTIN.include?(name)
              self
            end

            # Reset custom registrations. Intended for specs.
            def reset!
              @custom = []
              self
            end

            def custom
              @custom.dup
            end
          end
        end
      end
    end
  end
end
