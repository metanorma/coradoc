# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class Header < Base
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
