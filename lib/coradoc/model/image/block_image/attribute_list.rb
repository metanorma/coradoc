# frozen_string_literal: true

module Coradoc
  module Model
    class BlockImage < Coradoc::Model::Image::Core
      class AttributeList < Coradoc::Model::Image::Core::AttributeList

        extend AttributeList::Matchers

        def named_validators
          super.merge({
            caption: String,
            align: one("left", "center", "right"),
            float: one("left", "right"),
          })
        end
      end
    end
  end
end
