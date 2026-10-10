# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    # Canonical AsciiDoc formatter (#110): parse to the format model
    # tree, serialize, then normalize inter-block whitespace. Blank
    # lines inside verbatim/example fences are preserved — the pass
    # tracks delimiter pairs and only squeezes outside them.
    module Formatter
      FENCE = /\A(?:[-=*_']{4,})\s*\z/

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
            fence = nil if FENCE.match?(stripped) && stripped == fence
          elsif FENCE.match?(stripped)
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
        out.join.sub(/\n+\z/, "\n")
      end

      # Exactly one blank line between blocks; none before the first
      # content line.
      def emit_blanks(out, blanks)
        out << "\n" if blanks.positive? && !out.empty?
      end
    end
  end
end
