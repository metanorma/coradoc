# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Html
    module Drop
      class TextContentDrop < Base
        def text
          Escape.escape_html(@model.text.to_s)
        end
      end

      DropFactory.register(CoreModel::TextContent, TextContentDrop)
    end
  end
end
