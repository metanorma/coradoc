# frozen_string_literal: true

module Coradoc
  module Markdown
    # Text model representing plain text content.
    #
    class Text < Base
      attribute :content, :string

      prepend Behaviors::Text
    end
  end
end
