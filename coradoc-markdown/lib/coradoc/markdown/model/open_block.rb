# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Markdown
    # Open block — generic container that groups content without semantic
    # formatting. Used in AsciiDoc to apply IDs/attributes to a group.
    #
    # Markdown has no native container. The serializer's OpenBlock strategy:
    #   - Without id/classes → emit children as siblings (no wrapper)
    #   - With id/classes    → emit `<div id="...">...</div>` wrapper
    class OpenBlock < Base
      attribute :children, Coradoc::Markdown::Base, collection: true, default: []

      def initialize(children: [], **rest)
        super
        @children = Array(children)
      end
    end
  end
end
