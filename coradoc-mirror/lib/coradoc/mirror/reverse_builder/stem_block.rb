# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class StemBlock < Base
        def build(node)
          attrs = node.attrs
          CoreModel::StemBlock.new(
            content: attrs&.text || extract_text(node),
            language: attrs&.language || 'latex',
            title: attrs&.title
          )
        end
      end
    end
  end
end
