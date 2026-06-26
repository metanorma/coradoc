# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      class OpenBlock < Base
        registers 'open_block'

        def build(node)
          CoreModel::OpenBlock.new(children: build_content(node))
        end
      end
    end
  end
end
