# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      class Document < Base
        registers 'doc'

        def build(node)
          attrs = node.attrs
          CoreModel::DocumentElement.new(
            title: attrs&.title,
            id: attrs&.id,
            children: build_content(node)
          )
        end
      end
    end
  end
end
