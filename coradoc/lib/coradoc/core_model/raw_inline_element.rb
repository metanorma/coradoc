# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Inline raw passthrough — content the source format marked as "do not
    # process". AsciiDoc's `+++raw+++` is the canonical producer. Spokes
    # that lack a passthrough concept (most of them) should emit the
    # content verbatim, since the original author explicitly chose raw
    # markup (often HTML) knowing it would be passed through.
    class RawInlineElement < InlineElement
      def self.format_type
        'raw_inline'
      end
    end
  end
end
