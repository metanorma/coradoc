# frozen_string_literal: true

module Coradoc
  module Roundtrip
    # Extracts short, line-numbered excerpts of a text.
    module Snippet
      CONTEXT = 1
      MAX_WIDTH = 120

      module_function

      # @param text [String]
      # @param line [Integer] 1-based line to centre on
      # @return [String]
      def around(text, line)
        lines = text.lines
        from = [line - 1 - CONTEXT, 0].max
        to = [line - 1 + CONTEXT, lines.size - 1].min
        (from..to).map { |i| format('%<n>4d| %<s>s', n: i + 1, s: clip(lines[i].to_s.chomp)) }.join("\n")
      end

      # @return [Integer, nil] 1-based number of the first line that differs
      def first_difference(left, right)
        a = left.lines
        b = right.lines
        index = [a.size, b.size].max.times.find { |i| a[i] != b[i] }
        index && (index + 1)
      end

      def clip(line)
        line.length > MAX_WIDTH ? "#{line[0, MAX_WIDTH]}…" : line
      end
    end
  end
end
