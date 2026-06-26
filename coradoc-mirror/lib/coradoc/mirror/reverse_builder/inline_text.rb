# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      class InlineText < Base
        registers 'dt', 'dd'

        def build(node)
          children = build_inline_children(node)
          text = children.map { |c| c.is_a?(CoreModel::TextContent) ? c.text : '' }.join
          CoreModel::InlineElement.new(content: text)
        end
      end
    end
  end
end
