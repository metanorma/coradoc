# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Html
    module Drop
      class DefinitionListDrop < Base
        def items
          children_to_liquid(@model.items)
        end
      end
    end
  end
end
