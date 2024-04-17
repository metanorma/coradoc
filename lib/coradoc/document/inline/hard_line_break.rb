module Coradoc
  module Document
    module Inline
      class HardLineBreak
        def to_adoc
          " +\n"
        end
      end
    end
  end
end
