module Coradoc
  module Element
    module Image
      class InlineImage < Core
        def initialize(title, id, src, options = {})
          super
          @colons = ":"
        end
      end
    end
  end
end
