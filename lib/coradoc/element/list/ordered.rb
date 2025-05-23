module Coradoc
  module Element
    module List
      class Ordered < Core
        def initialize(items:, id: nil, ol_count: nil, attrs: AttributeList.new)
          super(items: items, id: id, ol_count: ol_count, attrs: attrs)
        end

        def prefix
          return @marker if @marker

          "." * [@ol_count, 1].max
        end
      end
    end
  end
end
