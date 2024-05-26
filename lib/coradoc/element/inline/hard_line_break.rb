module Coradoc
  module Element
    module Inline
      class HardLineBreak < Base
        def to_adoc
          " +\n"
        end
      end
    end
  end
end
