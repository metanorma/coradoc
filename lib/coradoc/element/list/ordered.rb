module Coradoc
  module Element
    module List
      class Ordered < Core
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
