# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      class Blockquote < Base
        registers 'quote'

        def build(node)
          CoreModel::QuoteBlock.new(
            attribution: node.attrs&.attribution,
            children: build_content(node)
          )
        end
      end
    end
  end
end
