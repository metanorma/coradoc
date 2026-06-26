# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      class TocEntry < Base
        registers 'toc_entry'

        def build(node)
          attrs = node.attrs
          CoreModel::TocEntry.new(id: attrs&.id, title: attrs&.title)
        end
      end
    end
  end
end
