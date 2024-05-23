module Coradoc
  module Element
    module Image
      class BlockImage < Core
        def initialize(title, id, src, options = ())
          super(title, id, src, options)
          @colons = "::"
        end

        def validate_named
          @attributes.validate_named(VALIDATORS_NAMED, VALIDATORS_NAMED_BLOCK)
        end

        extend AttributeList::Matchers
        VALIDATORS_NAMED_BLOCK = {
          caption: String,
          align: one("left", "center", "right"),
          float: one("left", "right"),
        }
      end
    end
  end
end
