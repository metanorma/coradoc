module Coradoc
  module Document
    class Image
      class BlockImage < Image
        def initialize(title, id, src, options = ())
          super(title, id, src, options)
          @colons = "::"
        end
      end
    end
  end
end
