module Coradoc
  module Element
    module Inline
      class Small < Base
        attr_accessor :text

        declare_children :text

        def initialize(text, options = {})
          @text = text
        end

        def to_adoc
          "[.small]##{@text}#"
        end
      end
    end
  end
end
