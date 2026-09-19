# frozen_string_literal: true

require 'parsanol'

module Coradoc
  module Markdown
    module Parser
      # Custom grammar atoms and DSL surface for the Markdown parser,
      # built on Parsanol::Atoms::Custom — the sanctioned extension
      # point. Replaces the former parslet_extras module, which
      # reached into Parslet internals via refinements.
      module ParsanolAtoms
        # Matches +parslet+ but yields a fixed +value+.
        class Output < Parsanol::Atoms::Custom
          attr_reader :parslet, :value

          def initialize(parslet, value)
            @parslet = parslet
            @value = value
            super()
          end

          def try_match(source, context, consume_all)
            success, = parslet.apply(source, context, consume_all)
            [success, success ? value : nil]
          end
        end

        # Matches +parslet+ and yields the callable applied to the
        # flattened match value.
        class DynamicOutput < Parsanol::Atoms::Custom
          include Parsanol::Atoms::CanFlatten

          attr_reader :parslet, :callable

          def initialize(parslet, callable)
            @parslet = parslet
            @callable = callable
            super()
          end

          def try_match(source, context, consume_all)
            success, value = parslet.apply(source, context, consume_all)
            return [false, nil] unless success

            [true, callable.call(flatten(value))]
          end
        end

        # Positive/negative lookbehind: succeeds (zero-width) when the
        # preceding +number+ characters are/are not matched by
        # +bound_parslet+. Character-accurate for multibyte input —
        # rewinds over UTF-8 continuation bytes.
        class Lookbehind < Parsanol::Atoms::Custom
          attr_reader :positive, :number, :bound_parslet

          def initialize(bound_parslet, number, positive: true)
            @positive = positive
            @number = number
            @bound_parslet = bound_parslet
            super()
          end

          def error_msgs
            @error_msgs ||= {
              positive: ['Input should be preceded by ', bound_parslet],
              negative: ['Input should not be preceded by ', bound_parslet]
            }
          end

          def try_match(source, context, _consume_all)
            rewind_pos = source.bytepos
            if rewind_pos.zero?
              return [true, nil] unless positive

              return context.err_at(self, source, error_msgs[:positive], source.pos)
            end

            source.bytepos = rewind_chars(source, number)
            error_pos = source.pos
            success, = bound_parslet.apply(source, context, false)

            if positive
              return [true, nil] if success

              context.err_at(self, source, error_msgs[:positive], error_pos)
            elsif success
              context.err_at(self, source, error_msgs[:negative], error_pos)
            else
              [true, nil]
            end
          ensure
            source.bytepos = rewind_pos
          end

          private

          def rewind_chars(source, nchars)
            input = source.input
            pos = source.bytepos
            nchars.times do
              pos -= 1
              pos -= 1 while pos.positive? && (input.getbyte(pos) & 0xC0) == 0x80
            end
            [pos, 0].max
          end
        end
      end
    end
  end
end

# Additive DSL surface (no overrides): exposes the custom atoms on
# every atom the way the former parslet_extras refinements did.
module Parsanol
  module Atoms
    module DSL
      def output(value)
        Coradoc::Markdown::Parser::ParsanolAtoms::Output.new(self, value)
      end

      def dynamic_output(callable)
        Coradoc::Markdown::Parser::ParsanolAtoms::DynamicOutput.new(self, callable)
      end

      def precedes?(num = 1)
        Coradoc::Markdown::Parser::ParsanolAtoms::Lookbehind.new(self, num, positive: true)
      end

      def does_not_precede?(num = 1)
        Coradoc::Markdown::Parser::ParsanolAtoms::Lookbehind.new(self, num, positive: false)
      end
    end
  end
end
