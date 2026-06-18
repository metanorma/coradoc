# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Markdown
    # Verse block — preformatted text preserving line breaks but allowing
    # inline formatting. Distinct from a literal block (no formatting)
    # or a code block (no formatting + language hint).
    #
    # Markdown has no native verse. Serialized as a blockquote with the
    # understanding that verse semantics are lost but line breaks are
    # preserved via hard line breaks.
    class Verse < Base
      attribute :content, :string
      attribute :attribution, :string
      attribute :citetitle, :string

      def initialize(content:, attribution: nil, citetitle: nil, **rest)
        super
        @content = content
        @attribution = attribution
        @citetitle = citetitle
      end
    end
  end
end
