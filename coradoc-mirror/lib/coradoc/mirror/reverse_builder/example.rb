# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class Example < Base
        def build(node)
          CoreModel::ExampleBlock.new(
            title: node.attrs&.title,
            children: build_content(node)
          )
        end
      end
    end
  end
end
