# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Html
    module Drop
      class ImageDrop < Base
        def inline?
          @model.inline == true
        end

        def src
          @model.src
        end

        def alt
          @model.alt
        end

        def width
          @model.width
        end

        def height
          @model.height
        end

        def caption
          optional_text(@model.caption)
        end
      end

      DropFactory.register(CoreModel::Image, ImageDrop)
    end
  end
end
