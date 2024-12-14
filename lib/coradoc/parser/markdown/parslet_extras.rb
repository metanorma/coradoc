require "parslet"
require "parslet/convenience"

module Coradoc
  module Parser
    module Markdown
      module ParsletExtras
        refine Parslet::Scope do
          attr_reader :current

          def has_key?(...)
            @current.has_key?(...)
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
        # NOTE: Parslet only accepts hashes and arrays
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

        refine Parslet::Atoms::DSL do
          def output(value)
            Output.new(self, value)
          end
        end
      end
    end
  end
end
