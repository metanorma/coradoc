module Coradoc
  module Element
    module Image
      class InlineImage < Core
        def initialize(title:, src:, id: nil, attributes: AttributeList.new,
annotate_missing: nil, line_break: "")
          super
          @colons = ":"
        end
      end
    end
  end
end
