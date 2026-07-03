# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    # Single source of truth for AsciiDoc's typographic quote substitution.
    #
    # Asciidoctor replaces four 2-char patterns with the corresponding
    # Unicode curly quotes. Both the parser (to recognise the patterns)
    # and the transformer (to emit the Unicode chars) reference this
    # module — the mapping lives here, not on either consumer, so the
    # parser/transformer seam stays clean.
    #
    # The patterns MUST be recognised before +monospace_constrained+ in
    # the +inline+ alternation, otherwise the lone backtick in +`"`+ or
    # +`"``+ fires monospace and the surrounding quote collapses to
    # straight ASCII quotes wrapped around a spurious code span.
    module TypographicQuotes
      PATTERN_TO_CHAR = {
        '"`' => "“",  # U+201C left double
        '`"' => "”",  # U+201D right double
        "'`" => "‘",  # U+2018 left single
        "`'" => "’"   # U+2019 right single
      }.freeze

      # All four 2-char patterns, suitable for building a Parslet alternation.
      # @return [Array<String>]
      PATTERNS = PATTERN_TO_CHAR.keys.freeze

      # Look up the Unicode char for a matched pattern.
      # @param pattern [String, Parslet::Slice] the matched 2-char pattern
      # @return [String] the Unicode curly quote char
      def self.char_for(pattern)
        PATTERN_TO_CHAR.fetch(pattern.to_s, pattern.to_s)
      end
    end
  end
end
