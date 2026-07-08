# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Markdown
    # Admonition block — a callout like NOTE, WARNING, TIP, etc.
    #
    # Markdown has no native admonition syntax (GFM Alerts since Dec 2023
    # notwithstanding — see admonition/gfm_alert strategy). The
    # `admonition_style` config option selects the output form:
    #
    #   :github   → > **NOTE:** text         (broad compat)
    #   :gfm_alert → > [!NOTE]\n> text        (GFM native since 2024)
    #   :container → :::note\n... \n:::        (VitePress / markdown-it)
    #   :html     → <div class="note">...</div>
    #
    # Type is stored lowercase. Content is raw Markdown text (already
    # serialized). Title is optional.
    class Admonition < Base
      ALLOWED_TYPES = %w[note tip warning important caution].freeze

      attribute :admonition_type, :string
      attribute :content, :string
      attribute :title, :string

      # Mixed inline content (strings and inline model objects) carried
      # from the CoreModel children so serializers can preserve cross
      # references, code spans, etc. When empty, fall back to `content`.
      attribute :children, Coradoc::Markdown::Base, collection: true, default: []

      # Normalize type on assignment. Callers can pass "NOTE", "Note",
      # or "note" — storage is always lowercase so downstream comparison
      # and CSS class generation don't need to repeat the normalization.
      def admonition_type=(value)
        super(value.to_s.downcase)
      end
    end
  end
end
