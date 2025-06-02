module Coradoc
  module Model
    module Break
      class ThematicBreak < Base
        def to_asciidoc
          "\n* * *\n"
        end
      end
    end
  end
end
