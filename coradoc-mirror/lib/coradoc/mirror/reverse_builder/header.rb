# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      class Header < Base
        registers 'floating_title', 'heading'

        def build(node)
          attrs = node.attrs
          CoreModel::HeaderElement.new(
            title: attrs&.title,
            level: attrs&.level,
            children: build_content(node)
          )
        end
      end
    end
  end
end
