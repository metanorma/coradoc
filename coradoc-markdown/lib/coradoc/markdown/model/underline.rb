# frozen_string_literal: true

module Coradoc
  module Markdown
    class Underline < Base
      attribute :text, :string

      def to_md
        "<u>#{text}</u>"
      end
    end
  end
end
