module Coradoc
  module Element
    module Inline
      class Anchor < Base
        attr_accessor :id

        declare_children :id

        def initialize(id:)
          @id = id
        end

        def to_adoc
          "[[#{@id}]]"
        end
      end
    end
  end
end
