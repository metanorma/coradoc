module Coradoc
  module Element
    module Break
      class ThematicBreak < Base
        def to_adoc
          "\n* * *\n"
        end
      end
    end
  end
end
