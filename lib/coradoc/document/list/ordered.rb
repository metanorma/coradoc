module Coradoc
  module Document
    class List
      class Ordered < List
        def initialize(items, options = {})
          super(items, options)
        end

        def prefix
          "." * [@ol_count, 0].max
        end
      end
    end
  end
end
