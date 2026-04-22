# frozen_string_literal: true

module Coradoc
  module Markdown
    # List model representing a Markdown list (ordered or unordered).
    #
    # @example Create an unordered list
    #   list = Coradoc::Markdown::List.new(
    #     ordered: false,
    #     items: [
    #       Coradoc::Markdown::ListItem.new(text: "Item 1"),
    #       Coradoc::Markdown::ListItem.new(text: "Item 2")
    #     ]
    #   )
    #
    class List < Base
      attribute :ordered, :boolean, default: false
      attribute :items, Coradoc::Markdown::ListItem, collection: true
      attribute :start_number, :integer, default: 1
    end
  end
end
