# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      class LiteralBlock < Base
        registers 'literal'

        def build(node)
          attrs = node.attrs
          CoreModel::LiteralBlock.new(
            content: attrs&.text || extract_text(node),
            language: attrs&.language,
            title: attrs&.title
          )
        end
      end
    end
  end
end
