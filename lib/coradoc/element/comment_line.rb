module Coradoc
  module Element
    module Comment
      class Line < Base
        attr_accessor :text

        def initialize(text, options = {})
          @text = text
          @line_break = options.fetch(:line_break, "\n")
        end

        def to_adoc
          "// #{@text}#{@line_break}"
        end
      end
    end
  end
end
