# frozen_string_literal: true

module Coradoc
  module Html
    module Drop
      class ListBlockDrop < Base
        def html_tag
          TagMapping.tag_for(@model.marker_type)
        end

        def items
          children_to_liquid(@model.items)
        end
      end

      DropFactory.register(CoreModel::ListBlock, ListBlockDrop)
    end
  end
end
