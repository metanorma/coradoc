# frozen_string_literal: true

module Coradoc
  module Markdown
    # ListItem model representing an item in a Markdown list.
    #
    class ListItem < Base
      attribute :text, :string
      attribute :checked, :boolean # For task lists (- [ ] or - [x])
      attribute :sublist, Coradoc::Markdown::List # Nested list

      # Mixed content (strings and inline model objects)
      # @return [Array] mixed content array
      attr_reader :children

      def initialize(args = {})
        super()
        @text = args[:text] || ''
        @checked = args[:checked]
        @sublist = args[:sublist]
        @children = args[:children] || []
      end

      def children=(value)
        @children = value || []
      end
    end
  end
end
