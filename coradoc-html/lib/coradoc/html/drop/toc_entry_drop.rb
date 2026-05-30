# frozen_string_literal: true

require_relative 'base'
require_relative '../title_text'

module Coradoc
  module Html
    module Drop
      class TocEntryDrop < Base
        def title
          TitleText.escape(@model.title)
        end

        def number
          @model.number
        end

        def level
          @model.level
        end

        def children
          children_to_liquid(@model.children)
        end

        def numbered_title
          n = number
          n ? "#{n}. #{title}" : title
        end
      end

      DropFactory.register(CoreModel::TocEntry, TocEntryDrop)
    end
  end
end
