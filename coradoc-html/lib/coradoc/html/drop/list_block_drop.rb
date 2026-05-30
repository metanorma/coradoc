# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Html
    module Drop
      class ListBlockDrop < Base
        def html_tag
          case @model.marker_type
          when 'ordered' then 'ol'
          when 'definition' then 'dl'
          else 'ul'
          end
        end

        def items
          children_to_liquid(@model.items)
        end
      end

      DropFactory.register(CoreModel::ListBlock, ListBlockDrop)
    end
  end
end
