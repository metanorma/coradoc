# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class Partintro < Base
        def build(node)
          CoreModel::PartintroBlock.new(
            title: node.attrs&.title,
            id: node.attrs&.id,
            children: build_content(node)
          )
        end
      end
    end
  end
end
