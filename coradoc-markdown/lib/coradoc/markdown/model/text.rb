# frozen_string_literal: true

module Coradoc
  module Markdown
    # Text model representing plain text content.
    #
    class Text < Base
      attribute :content, :string

      def to_s
        content
      end
    end
  end
end
