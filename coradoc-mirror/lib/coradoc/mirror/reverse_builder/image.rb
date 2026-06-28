# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class Image < Base
        def build(node)
          attrs = node.attrs
          CoreModel::Image.new(
            src: attrs&.src,
            alt: attrs&.alt,
            title: attrs&.title,
            caption: attrs&.caption,
            width: attrs&.width,
            height: attrs&.height
          )
        end
      end
    end
  end
end
