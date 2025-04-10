# frozen_string_literal: true

module Coradoc
  module Model
    module Inline
      class HardLineBreak < Base
        def to_asciidoc
          " +\n"
        end
      end
    end
  end
end
