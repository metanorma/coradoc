# frozen_string_literal: true

module Coradoc
  module Markdown
    class Subscript < Base
      attribute :text, :string

      def to_md
        "<sub>#{text}</sub>"
      end
    end
  end
end
