module Coradoc
  module Element
    module Inline
      class Footnote < Base
        attr_accessor :text, :id

        declare_children :text, :id

        def initialize(text, id = nil)
          @text = text
          @id = id
        end

        def to_adoc
          if @id
            "footnote:#{@id}[#{@text}]"
          else
            "footnote:[#{@text}]"
          end
        end
      end
    end
  end
end
