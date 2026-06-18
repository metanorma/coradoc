# frozen_string_literal: true

require_relative '../element_serializer'

module Coradoc
  module Markdown
    class Serializer
      module Serializers
        # Hard line break. Output depends on `config.hard_break` (not
        # part of the 5 spec options yet — defaults to CommonMark
        # two-trailing-spaces).
        class HardLineBreak < ElementSerializer
          handles_type ::Coradoc::Markdown::HardLineBreak

          def call(_element, _ctx)
            "  \n"
          end
        end
      end
    end
  end
end
