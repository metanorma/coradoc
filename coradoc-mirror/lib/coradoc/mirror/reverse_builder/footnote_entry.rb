# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      class FootnoteEntry < Base
        registers 'footnote_entry'

        def build(node)
          attrs = node.attrs
          CoreModel::Footnote.new(id: attrs&.id, content: extract_text(node))
        end
      end
    end
  end
end
