require "parslet"
require "parslet/convenience"

module Coradoc
  module Parser
    module Markdown
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

          def has_key?(...)
            @current.has_key?(...)
          end

          def root
            scope = current
            scope = scope.parent while scope.parent
            scope
          end
        end

        refine Parslet::Scope::Binding do
          def has_key?(...)
            @hash.has_key?(...)
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

            @parslet, @value = parslet, value
          end
  
          def apply(source, context, consume_all)
            success, _ = result = parslet.apply(source, context, consume_all)

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

            @parslet, @callable = parslet, callable
          end
  
          def apply(source, context, consume_all)
            success, value = result = parslet.apply(source, context, consume_all)

            return result unless success
            succ(@callable.(flatten(value)))
          end
  
          def to_s_inner(prec)
            "#{callable}:#{parslet.to_s(prec)}"
          end
        end

        class Lookbehind < Parslet::Atoms::Base
          using ParsletExtras
          attr_reader :positive
          attr_reader :number
          attr_reader :bound_parslet
  
          def initialize(bound_parslet, number, positive=true)
            super()
    
            # Model positive and negative lookbehind by testing this flag.
            @positive = positive
            @number = number
            @bound_parslet = bound_parslet
          end

          def error_msgs
            @error_msgs ||= {
              :positive => ["Input should be preceded by ", bound_parslet],
              :negative => ["Input should not be preceded by ", bound_parslet]
            }
          end
  
          def try(source, context, consume_all)
            rewind_pos = source.bytepos
            if source.bytepos == 0
              return succ(nil) unless positive
              return context.err_at(self, source, error_msgs[:positive], source.pos)
            end
            source.rewind(number)
            error_pos = source.pos

            success, x = bound_parslet.apply(source, context, consume_all)

            if positive
              return succ(nil) if success
              return context.err_at(self, source, error_msgs[:positive], error_pos)
            else
              return succ(nil) unless success
              return context.err_at(self, source, error_msgs[:negative], error_pos)
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
        class Parslet::Atoms::Check < Parslet::Atoms::Base
          attr_reader :block

          def initialize(block)
            @block = block
          end

          def cached?
            false
          end

          def try(source, context, consume_all)
            [block.call(source, context), nil]
          end

          def to_s_inner(prec)
            "check { ... }"
          end
        end

        refine Parslet do
          def check(&block)
            Parslet::Atoms::Check.new(block)
          end
          module_function :check
        end

        refine Parslet::Atoms::DSL do
          def output(value)
            Output.new(self, value)
          end

          def dynamic_output(value)
            DynamicOutput.new(self, value)
          end

          def precedes?(num=1)
            Lookbehind.new(self, num, true)
          end

          def does_not_precede?(num=1)
            Lookbehind.new(self, num, false)
          end
        end
      end
    end
  end
end
