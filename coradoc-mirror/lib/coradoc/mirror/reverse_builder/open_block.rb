# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class OpenBlock < Base
        def build(node)
          CoreModel::OpenBlock.new(children: build_content(node))
        end
      end
    end
  end
end
