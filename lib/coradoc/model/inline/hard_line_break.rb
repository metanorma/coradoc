# frozen_string_literal: true

module Coradoc
  module Model
    module Inline
      class HardLineBreak < Base
        asciidoc do
          map_model to: Coradoc::Element::Inline::HardLineBreak
        end

        def to_asciidoc
          " +\n"
        end
      end
    end
  end
end
