# frozen_string_literal: true

module Coradoc
  module Html
    module Drop
      class ListItemDrop < Base
        def content
          content_to_liquid(@model.content)
        end

        def nested_list
          child = @model.nested_list
          DropFactory.create(child) if child
        end
      end

      DropFactory.register(CoreModel::ListItem, ListItemDrop)
    end
  end
end
