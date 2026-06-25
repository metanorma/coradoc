# frozen_string_literal: true

module Coradoc
  module CoreModel
    # A leveloffset value parsed from an include directive.
    #
    # asciidoctor supports two forms:
    #   leveloffset=+N   → relative shift (heading.level += N)
    #   leveloffset=-N   → relative shift (heading.level -= N)
    #   leveloffset=N    → absolute set (heading.level = N)
    #
    # The parsed form keeps the mode and delta separate so that the
    # selector that applies the offset does not need to re-parse the
    # string each time it walks a section (DRY).
    class IncludeLevelOffset < Base
      # "relative" (+N/-N) or "absolute" (bare N).
      attribute :mode, :string

      # Signed integer for relative shifts; the absolute target level
      # for absolute mode.
      attribute :delta, :integer

      # Construct from a raw asciidoctor-style string ("+2", "-1", "3").
      # Returns nil if the input is nil or unparsable.
      #
      # @param raw [String, nil]
      # @return [IncludeLevelOffset, nil]
      def self.parse(raw)
        return nil if raw.nil? || raw.strip.empty?

        matched_offset(raw.strip)
      end

      # Apply this offset to a heading level (1-indexed asciidoctor level).
      #
      # @param level [Integer] original section level
      # @return [Integer] new section level, clamped to >= 0
      def apply(level)
        case mode
        when 'relative' then [level + delta, 0].max
        when 'absolute' then [delta, 0].max
        else level
        end
      end

      # Render back to the asciidoctor wire form ("+2", "-1", "3").
      #
      # @return [String]
      def to_s
        case mode
        when 'relative' then format('%+d', delta)
        when 'absolute' then delta.to_s
        else ''
        end
      end

      class << self
        private

        def matched_offset(trimmed)
          %r{\A(?<sign>[+-]?)(?<digits>\d+)\z}.match(trimmed) do |m|
            digits = m[:digits].to_i
            signed = m[:sign] == '-' ? -digits : digits
            mode = m[:sign].empty? ? 'absolute' : 'relative'
            new(mode: mode, delta: signed)
          end
        end
      end
    end
  end
end
