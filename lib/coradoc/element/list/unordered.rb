module Coradoc
  module Element
    module List
      class Unordered < Core
        def initialize(items:, id: nil, ol_count: nil, attrs: AttributeList.new)
          super
        end

        def prefix
          return @marker if @marker

          "*" * [@ol_count, 1].max
        end
      end
    end
  end
end
