# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class FootnoteEntry < Base
        def build(node)
          attrs = node.attrs
          CoreModel::Footnote.new(id: attrs&.id, content: extract_text(node))
        end
      end
    end
  end
end
