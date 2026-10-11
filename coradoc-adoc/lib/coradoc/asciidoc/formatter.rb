# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    # Canonical AsciiDoc formatter (#110): parse to the format model
    # tree, serialize, then normalize inter-block whitespace. Blank
    # lines inside verbatim/example fences are preserved — the pass
    # tracks delimiter pairs and only squeezes outside them.
    module Formatter
      # Delimiter-line fence characters: listings, examples, sidebars,
      # quotes, passthroughs, thematic breaks. A fence is 4+ repetitions
      # of ONE character (CodeQL rb/polynomial-redos: the earlier regex
      # form flagged as polynomial; a same-char scan is linear and also
      # stricter — mixed runs are not fences).
      FENCE_CHARACTERS = %w[- = * _ ' +].freeze

      module_function

      def call(text)
        canonical_whitespace(Coradoc::AsciiDoc.parse(text).to_adoc)
      end

      def canonical_whitespace(adoc)
        out = []
        blanks = 0
        fence = nil

        adoc.lines.each do |line|
          stripped = line.strip

          if fence
            out << line
            fence = nil if stripped == fence && fence_delimiter(stripped)
          elsif fence_delimiter(stripped)
            emit_blanks(out, blanks)
            blanks = 0
            out << line
            fence = stripped
          elsif stripped.empty?
            blanks += 1
          else
            emit_blanks(out, blanks)
            blanks = 0
            out << line
          end
        end
        joined = out.join
        return joined if joined.empty?

        # Exactly one trailing newline — a reverse scan, not a regex
        # (CodeQL rb/polynomial-redos models /\n+\z/ as polynomial).
        end_index = joined.length
        end_index -= 1 while end_index.positive? && joined[end_index - 1] == "\n"
        "#{joined[0, end_index]}\n"
      end

      # The delimiter character when +stripped+ is a fence line
      # (4+ repetitions of one fence character); nil otherwise.
      def fence_delimiter(stripped)
        return nil unless stripped.length >= 4

        first = stripped[0]
        return nil unless FENCE_CHARACTERS.include?(first)

        stripped.each_char.all?(first) ? first : nil
      end

      # Exactly one blank line between blocks; none before the first
      # content line.
      def emit_blanks(out, blanks)
        out << "\n" if blanks.positive? && !out.empty?
      end
    end
  end
end
