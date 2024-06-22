module Coradoc
  module Element
    module Comment
      class Block < Base
        attr_accessor :text

        def initialize(text, options = {})
          @text = text
          @line_break = options.fetch(:line_break, "\n")
        end

        def to_adoc
          "////\n" +
          "#{@text}\n" +
          "////#{@line_break}"
        end
      end
    end
  end
end
