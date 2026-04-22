# frozen_string_literal: true

module Coradoc
  module Markdown
    # ListItem model representing an item in a Markdown list.
    #
    class ListItem < Base
      attribute :text, :string
      attribute :checked, :boolean # For task lists (- [ ] or - [x])
      attribute :sublist, Coradoc::Markdown::List # Nested list
    end
  end
end
