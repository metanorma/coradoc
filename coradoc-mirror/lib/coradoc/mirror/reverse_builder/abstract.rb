# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      class Abstract < Base
        registers 'abstract_block'

        def build(node)
          CoreModel::AbstractBlock.new(
            title: node.attrs&.title,
            id: node.attrs&.id,
            children: build_content(node)
          )
        end
      end
    end
  end
end
