# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class Text < Base
        def build(node)
          text = node.text || ''
          marks = node.marks || []

          return CoreModel::TextContent.new(text: text) if marks.empty?

          marks.reduce(CoreModel::TextContent.new(text: text)) do |current, mark|
            apply_mark(current, mark)
          end
        end
      end
    end
  end
end
