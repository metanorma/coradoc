# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Html
    module Drop
      class TocDrop < Base
        def entries
          children_to_liquid(@model.entries)
        end
      end

      DropFactory.register(CoreModel::Toc, TocDrop)
    end
  end
end
