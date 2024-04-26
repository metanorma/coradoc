module Coradoc
  module Element
    module Image
      class BlockImage < Core
        def initialize(title, id, src, options = ())
          super(title, id, src, options)
          @colons = "::"
        end
      end
    end
  end
end
