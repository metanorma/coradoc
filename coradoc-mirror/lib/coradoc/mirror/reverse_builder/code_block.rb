# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class CodeBlock < Base
        def build(node)
          attrs = node.attrs
          CoreModel::SourceBlock.new(
            content: attrs&.text || extract_text(node),
            language: attrs&.language,
            title: attrs&.title
          )
        end
      end
    end
  end
end
