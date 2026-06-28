# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class Paragraph < Base
        def build(node)
          CoreModel::ParagraphBlock.new(children: build_inline_children(node))
        end
      end
    end
  end
end
