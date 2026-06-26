# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      class Bibliography < Base
        registers 'bibliography'

        def build(node)
          entries = build_content(node).select { |c| c.is_a?(CoreModel::BibliographyEntry) }
          CoreModel::Bibliography.new(title: node.attrs&.title, entries: entries)
        end
      end
    end
  end
end
