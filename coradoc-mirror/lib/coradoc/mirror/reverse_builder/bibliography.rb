# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class Bibliography < Base
        def build(node)
          entries = build_content(node).select { |c| c.is_a?(CoreModel::BibliographyEntry) }
          CoreModel::Bibliography.new(title: node.attrs&.title, entries: entries)
        end
      end
    end
  end
end
