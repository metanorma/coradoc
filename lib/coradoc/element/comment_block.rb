module Coradoc
  module Element
    module Comment
      class Block < Base
        attr_accessor :text

        def initialize(text:, line_break: "\n")
          @text = text
          @line_break = line_break
        end

        def to_adoc
          <<~ADOC.chomp
            ////
            #{@text}
            ////#{@line_break}
          ADOC
        end
      end
    end
  end
end
