# frozen_string_literal: true

module Coradoc
  module IncludeSelectors
    # Line-range selection. Parses asciidoctor-style specs:
    #
    #   N            single line
    #   A..B         inclusive range
    #   A..B;C;D..E  multiple, semicolon-separated
    #
    # Out-of-bounds clamps gracefully (SPEC 3.4). One-based indexing
    # (asciidoctor convention).
    module Lines
      SPEC_PART = %r{
        \A
        (?<start>\d+)
        (?:\.\.(?<finish>\d+))?
        \z
      }x.freeze

      # @param text [String]
      # @param options [Coradoc::CoreModel::IncludeOptions]
      # @return [String]
      def self.call(text, options:)
        return text unless options.lines?

        ranges = parse_spec(options.lines_spec, max: text.lines.length)
        return '' if ranges.empty?

        indices = ranges.flat_map { |start, finish| (start..finish).to_a }.uniq.sort
        text.lines.values_at(*indices.map { |i| i - 1 }).join
      end

      class << self
        private

        def parse_spec(spec, max:)
          spec.split(';').map(&:strip).filter_map do |part|
            parse_part(part, max: max)
          end
        end

        def parse_part(part, max:)
          SPEC_PART.match(part) do |m|
            start = m[:start].to_i
            finish = m[:finish] ? m[:finish].to_i : start
            [start, finish].minmax.map { |n| clamp(n, max: max) }
          end
        end

        def clamp(n, max:)
          return nil if n < 1
          return max if n > max

          n
        end
      end
    end
  end
end
