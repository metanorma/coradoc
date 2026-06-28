# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class Preamble < Base
        def build(node)
          CoreModel::PreambleElement.new(children: build_content(node))
        end
      end
    end
  end
end
