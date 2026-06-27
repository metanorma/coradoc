# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      class RawInline < Base
        registers 'raw_inline'

        def build(node)
          CoreModel::RawInlineElement.new(content: node.text.to_s)
        end
      end
    end
  end
end
