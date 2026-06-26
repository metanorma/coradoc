# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      class Example < Base
        registers 'example'

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
