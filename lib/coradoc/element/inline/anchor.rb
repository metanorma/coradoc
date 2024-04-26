module Coradoc
  module Element
    module Inline
      class Anchor
        attr_reader :id

        def initialize(id)
          @id = id
        end

        def to_adoc
          "[[#{@id}]]"
        end
      end
    end
  end
end
