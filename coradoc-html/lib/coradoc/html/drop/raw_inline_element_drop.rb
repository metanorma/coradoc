# frozen_string_literal: true

require_relative 'inline_element_drop'

module Coradoc
  module Html
    module Drop
      # Drop for CoreModel::RawInlineElement.
      #
      # Passthrough content is raw output-format markup (typically HTML)
      # that the source author explicitly marked as "emit verbatim." The
      # generic InlineElementDrop escapes content; this subclass skips
      # escaping so the rendered output mirrors the author's intent.
      #
      # The Liquid template is shared with InlineElementDrop — only the
      # data preparation differs.
      class RawInlineElementDrop < InlineElementDrop
        def text
          extract_text(@model.content).to_s
        end

        def template_type
          'inline_element'
        end
      end

      DropFactory.register(CoreModel::RawInlineElement, RawInlineElementDrop)
    end
  end
end
