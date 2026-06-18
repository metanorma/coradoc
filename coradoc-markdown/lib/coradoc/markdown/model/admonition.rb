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

      def initialize(admonition_type:, content:, title: nil, **rest)
        super
        @admonition_type = admonition_type.to_s.downcase
        @content = content
        @title = title
      end
    end
  end
end
