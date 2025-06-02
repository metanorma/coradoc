module Coradoc
  module Element
    module Inline
      class Underline < Base
        attr_accessor :text

        declare_children :text

        def initialize(text:)
          @text = text
        end

        def to_adoc
          "[.underline]##{@text}#"
        end
      end
    end
  end
end
