# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Markdown
    # Pass block — raw content passed through verbatim, never rendered as
    # Markdown. Used for embedding HTML or other markup directly.
    #
    # Markdown has no native pass concept; the content is emitted as-is
    # inside a `nomarkdown` kramdown extension or raw HTML passthrough.
    class Pass < Base
      attribute :content, :string

      def initialize(content:, **rest)
        super
        @content = content
      end
    end
  end
end
