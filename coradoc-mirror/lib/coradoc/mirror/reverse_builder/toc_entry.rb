# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class TocEntry < Base
        def build(node)
          attrs = node.attrs
          CoreModel::TocEntry.new(id: attrs&.id, title: attrs&.title)
        end
      end
    end
  end
end
