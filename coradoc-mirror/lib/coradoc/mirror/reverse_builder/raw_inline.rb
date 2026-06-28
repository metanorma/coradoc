# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class RawInline < Base
        def build(node)
          CoreModel::RawInlineElement.new(content: node.text.to_s)
        end
      end
    end
  end
end
