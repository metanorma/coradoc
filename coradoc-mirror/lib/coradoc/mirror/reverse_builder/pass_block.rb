# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      class PassBlock < Base
        registers 'pass'

        def build(node)
          attrs = node.attrs
          CoreModel::PassBlock.new(
            content: attrs&.text || extract_text(node),
            language: attrs&.language,
            title: attrs&.title
          )
        end
      end
    end
  end
end
