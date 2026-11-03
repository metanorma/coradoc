# frozen_string_literal: true

module Coradoc
  module Markdown
    module Behaviors
      # Hand-written behavior for Admonition. Prepended (not included) so
      # that the setter can call `super` into the attribute setter that
      # lutaml-model defines on the class itself.
      module Admonition
        ALLOWED_TYPES = %w[note tip warning important caution].freeze

        # Normalize type on assignment. Callers can pass "NOTE", "Note",
        # or "note" — storage is always lowercase so downstream comparison
        # and CSS class generation don't need to repeat the normalization.
        def admonition_type=(value)
          super(value.to_s.downcase)
        end
      end
    end
  end
end
