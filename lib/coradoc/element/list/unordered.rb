module Coradoc
  module Element
    module List
      class Unordered < Core
        def initialize(items, options = {})
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
