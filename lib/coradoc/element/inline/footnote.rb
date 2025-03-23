module Coradoc
  module Element
    module Inline
      class Footnote < Base
        attr_accessor :text

        declare_children :text

        def initialize(text, _options = {})
          @text = text
        end

        def to_adoc
          "footnote:[#{@text}]"
        end
      end
    end
  end
end
