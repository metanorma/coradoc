# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class BulletList < Base
        def build(node)
          items = build_content(node).select { |c| c.is_a?(CoreModel::ListItem) }
          CoreModel::ListBlock.new(marker_type: 'unordered', items: items)
        end
      end
    end
  end
end
