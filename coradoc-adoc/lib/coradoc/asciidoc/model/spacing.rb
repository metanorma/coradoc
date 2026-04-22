# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Value object for defining spacing behavior of document elements
      #
      # Provides a unified way to control spacing around blocks, replacing
      # the scattered spacing_* attributes and trailing_newlines.
      #
      # @example Default spacing
      #   spacing = Spacing.default
      #   # before_block: 0, after_close: 2
      #
      # @example Compact spacing (for lists)
      #   spacing = Spacing.compact
      #   # after_close: 1
      #
      # @example No spacing (last element)
      #   spacing = Spacing.none
      #   # after_close: 0, trailing_newlines: ""
      #
      # @example Custom spacing
      #   spacing = Spacing.new(
      #     before_block: 1,
      #     after_close: 3
      #   )
      #
      # @example Exact round-trip spacing
      #   spacing = Spacing.new(
      #     trailing_newlines: "\n\n\n"
      #   )
      #
      class Spacing
        # Number of newlines before the block element
        #
        # @return [Integer] newlines before block
        attr_reader :before_block

        # Number of newlines after opening delimiter
        # (for delimited blocks like ===, ****, etc.)
        #
        # @return [Integer] newlines after open delimiter
        attr_reader :after_open

        # Number of newlines before closing delimiter
        # (for delimited blocks)
        #
        # @return [Integer] newlines before close delimiter
        attr_reader :before_close

        # Number of newlines after closing delimiter
        # (most common spacing control)
        #
        # @return [Integer] newlines after close delimiter
        attr_reader :after_close

        # Exact trailing newlines for round-trip preservation
        # When nil, uses calculated spacing from after_close
        # When set to a string, uses that exact value
        #
        # @return [String, nil] exact trailing newlines or nil
        attr_reader :trailing_newlines

        # Create a new Spacing value object
        #
        # @param before_block [Integer] Newlines before block
        # @param after_open [Integer] Newlines after opening delimiter
        # @param before_close [Integer] Newlines before closing delimiter
        # @param after_close [Integer] Newlines after closing delimiter
        # @param trailing_newlines [String, nil] Exact trailing newlines for round-trip
        #
        # @example Create default spacing
        #   spacing = Spacing.new
        #
        # @example Create compact spacing
        #   spacing = Spacing.new(after_close: 1)
        #
        # @example Create exact spacing for round-trip
        #   spacing = Spacing.new(trailing_newlines: "\n\n")
        #
        def initialize(before_block: 0, after_open: 1, before_close: 1,
                       after_close: 2, trailing_newlines: nil)
          @before_block = before_block
          @after_open = after_open
          @before_close = before_close
          @after_close = after_close
          @trailing_newlines = trailing_newlines
          freeze
        end

        # Default spacing for standard blocks
        # Most blocks have 2 newlines after them
        #
        # @return [Spacing] Default spacing configuration
        #
        # @example Use default spacing
        #   paragraph.spacing = Spacing.default
        #
        def self.default
          new
        end

        # Compact spacing for tight layouts
        # Used in lists, nested blocks, etc.
        #
        # @return [Spacing] Compact spacing configuration
        #
        # @example Use compact spacing in lists
        #   list_item.spacing = Spacing.compact
        #
        def self.compact
          new(after_close: 1)
        end

        # No spacing after the element
        # Used for the last element in a container
        #
        # @return [Spacing] No trailing spacing configuration
        #
        # @example Use for last element
        #   last_paragraph.spacing = Spacing.none
        #
        def self.none
          new(after_close: 0, trailing_newlines: '')
        end

        # Check if this is the default spacing
        #
        # @return [Boolean] true if default spacing
        #
        def default?
          before_block.zero? &&
            after_open == 1 &&
            before_close == 1 &&
            after_close == 2 &&
            trailing_newlines.nil?
        end

        # Check if this is compact spacing
        #
        # @return [Boolean] true if compact spacing
        #
        def compact?
          before_block.zero? &&
            after_open == 1 &&
            before_close == 1 &&
            after_close == 1 &&
            trailing_newlines.nil?
        end

        # Check if this has no trailing spacing
        #
        # @return [Boolean] true if no trailing spacing
        #
        def none?
          after_close.zero? && trailing_newlines == ''
        end

        # Check if exact trailing newlines are set
        #
        # @return [Boolean] true if trailing_newlines is explicitly set
        #
        def exact_mode?
          !trailing_newlines.nil?
        end

        # Get the trailing newlines string
        #
        # Returns the exact trailing_newlines if set,
        # otherwise calculates from after_close
        #
        # @return [String] The trailing newlines string
        #
        # @example Get trailing newlines
        #   spacing = Spacing.new(after_close: 2)
        #   spacing.trailing # => "\n\n"
        #
        def trailing
          return trailing_newlines if exact_mode?

          "\n" * after_close
        end

        # Get newlines before block
        #
        # @return [String] Newlines before block
        #
        def before
          "\n" * before_block
        end

        # Get newlines after opening delimiter
        #
        # @return [String] Newlines after open
        #
        def after_open_newlines
          "\n" * after_open
        end

        # Get newlines before closing delimiter
        #
        # @return [String] Newlines before close
        #
        def before_close_newlines
          "\n" * before_close
        end

        # Create a new spacing with modified after_close value
        #
        # @param value [Integer] New after_close value
        # @return [Spacing] New spacing with modified value
        #
        # @example
        #   spacing = Spacing.default.with_after_close(3)
        #
        def with_after_close(value)
          Spacing.new(
            before_block: before_block,
            after_open: after_open,
            before_close: before_close,
            after_close: value,
            trailing_newlines: trailing_newlines
          )
        end

        # Create a new spacing with exact trailing newlines
        #
        # @param value [String] Exact trailing newlines
        # @return [Spacing] New spacing with exact trailing newlines
        #
        # @example
        #   spacing = Spacing.default.with_trailing("\n\n\n")
        #
        def with_trailing(value)
          Spacing.new(
            before_block: before_block,
            after_open: after_open,
            before_close: before_close,
            after_close: after_close,
            trailing_newlines: value
          )
        end

        # String representation for debugging
        #
        # @return [String] Debug string
        #
        def inspect
          "#<#{self.class.name} before=#{before_block} after_open=#{after_open} " \
            "before_close=#{before_close} after_close=#{after_close} " \
            "trailing=#{trailing_newlines.inspect}>"
        end
        alias to_s inspect

        # Two spacings are equal if all attributes match
        #
        # @param other [Object] Object to compare
        # @return [Boolean] true if equal
        #
        def ==(other)
          return false unless other.is_a?(Spacing)

          before_block == other.before_block &&
            after_open == other.after_open &&
            before_close == other.before_close &&
            after_close == other.after_close &&
            trailing_newlines == other.trailing_newlines
        end
        alias eql? ==

        # Hash code for use in Hash keys
        #
        # @return [Integer] Hash code
        #
        def hash
          [before_block, after_open, before_close, after_close, trailing_newlines].hash
        end
      end
    end
  end
end
