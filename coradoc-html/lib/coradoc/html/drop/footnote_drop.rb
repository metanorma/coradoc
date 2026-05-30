# frozen_string_literal: true

module Coradoc
  module Html
    module Drop
      class FootnoteDrop < Base
        def footnote_id
          @model.id || ''
        end

        def content
          Escape.escape_html(extract_text(@model.content || @model.inline_content))
        end

        def inline?
          footnote_id.empty?
        end
      end

      DropFactory.register(CoreModel::FootnoteReference, FootnoteDrop)
      DropFactory.register(CoreModel::Footnote, FootnoteDrop)
    end
  end
end
