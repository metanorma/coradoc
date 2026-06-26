# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      class Paragraph < Base
        registers 'paragraph'

        def build(node)
          CoreModel::ParagraphBlock.new(children: build_inline_children(node))
        end
      end
    end
  end
end
