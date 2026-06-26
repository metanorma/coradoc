# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      # Inline footnote marker (JS `footnote_marker`). The CoreModel
      # FootnoteReference holds the same id/ref/number triple.
      class FootnoteMarker < Base
        registers 'footnote_marker'

        def build(node)
          attrs = node.attrs
          CoreModel::FootnoteReference.new(
            id: attrs&.id,
            reference: attrs&.ref_id,
            number: attrs&.number
          )
        end
      end
    end
  end
end
