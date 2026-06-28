# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class Blockquote < Base
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
