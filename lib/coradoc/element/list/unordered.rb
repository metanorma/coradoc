module Coradoc
  module Element
    module List
      class Unordered < Core
        def initialize(items, options = {})
          super(items, options)
        end

        def prefix
          "*" * [@ol_count, 0].max
        end
      end
    end
  end
end
