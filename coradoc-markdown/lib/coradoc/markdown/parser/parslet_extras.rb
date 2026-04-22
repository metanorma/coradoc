# frozen_string_literal: true

require 'parslet'
require 'parslet/convenience'

module Coradoc
  module Markdown
    module Parser
      module ParsletExtras
        refine Parslet::Source do
          def rewind(nchars)
            # https://github.com/ruby/strscan/issues/122
            self.charpos = @str.charpos - nchars
          end

          def charpos=(pos)
            @str.reset
            @str.getch while @str.charpos < pos
          end

          def charpos
            @str.charpos
          end

          def peek_byte
            @str.peek(1)
          end
        end

        refine Parslet::Scope do
          attr_reader :current

          def key?(...)
            @current.key?(...)
          end

          def has_key?(...)
            @current.key?(...)
          end

          def root
            scope = current
            scope = scope.parent while scope.parent
            scope
          end
        end

        refine Parslet::Scope::Binding do
          def key?(...)
            @hash.key?(...)
          end

          def has_key?(...)
            @hash.key?(...)
          end

          def initialize_copy(original)
            super
            @hash = @hash.clone
          end
        end

        # like Named but returning other things
        class Output < Parslet::Atoms::Base
          attr_reader :parslet, :value

          def initialize(parslet, value)
            super()

            @parslet = parslet
            @value = value
          end

          def apply(source, context, consume_all)
            success, = result = parslet.apply(source, context, consume_all)

            return result unless success

            succ(@value)
          end

          def to_s_inner(prec)
            "#{value}:#{parslet.to_s(prec)}"
          end
        end

        class DynamicOutput < Parslet::Atoms::Base
          attr_reader :parslet, :callable

          def initialize(parslet, callable)
            super()

            @parslet = parslet
            @callable = callable
          end

          def apply(source, context, consume_all)
            success, value = result = parslet.apply(source, context, consume_all)

            return result unless success

            succ(@callable.call(flatten(value)))
          end

          def to_s_inner(prec)
            "#{callable}:#{parslet.to_s(prec)}"
          end
        end

        class Lookbehind < Parslet::Atoms::Base
          using ParsletExtras
          attr_reader :positive
          attr_reader :number, :bound_parslet

          def initialize(bound_parslet, number, positive: true)
            super()

            # Model positive and negative lookbehind by testing this flag.
            @positive = positive
            @number = number
            @bound_parslet = bound_parslet
          end

          def error_msgs
            @error_msgs ||= {
              positive: ['Input should be preceded by ', bound_parslet],
              negative: ['Input should not be preceded by ', bound_parslet]
            }
          end

          def try(source, context, consume_all)
            rewind_pos = source.bytepos
            if source.bytepos.zero?
              return succ(nil) unless positive

              return context.err_at(self, source, error_msgs[:positive], source.pos)
            end
            source.rewind(number)
            error_pos = source.pos

            success, = bound_parslet.apply(source, context, consume_all)

            if positive
              return succ(nil) if success

              context.err_at(self, source, error_msgs[:positive], error_pos)
            else
              return succ(nil) unless success

              context.err_at(self, source, error_msgs[:negative], error_pos)
            end
          ensure
            source.bytepos = rewind_pos
          end

          def to_s_inner(prec)
            @char = positive ? '&' : '!'
            "<#{@char}<#{number}<#{bound_parslet.to_s(prec)}"
          end
        end

        # Like Dynamic but does not return a further parslet, just a reject/accept boolean
        module ::Parslet
          module Atoms
            class Check < ::Parslet::Atoms::Base
              attr_reader :block

              def initialize(block)
                super()
                @block = block
              end

              def cached?
                false
              end

              def try(source, context, _consume_all)
                [block.call(source, context), nil]
              end

              def to_s_inner(_prec)
                'check { ... }'
              end
            end
          end
        end

        refine ::Parslet do
          def check(&block)
            ::Parslet::Atoms::Check.new(block)
          end
          module_function :check
        end

        refine ::Parslet::Atoms::DSL do
          def output(value)
            Output.new(self, value)
          end

          def dynamic_output(value)
            DynamicOutput.new(self, value)
          end

          def precedes?(num = 1)
            Lookbehind.new(self, num, positive: true)
          end

          def does_not_precede?(num = 1)
            Lookbehind.new(self, num, positive: false)
          end
        end
      end
    end
  end
end
