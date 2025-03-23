module Coradoc
  module Element
    module Inline
      class AttributeReference < Base
        attr_accessor :name

        declare_children :name

        def initialize(name)
          @name = name
        end

        def to_adoc
          "{#{@name}}"
        end
      end
    end
  end
end
