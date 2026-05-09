# frozen_string_literal: true

module Coradoc
  module Markdown
    class Superscript < Base
      attribute :text, :string

      def to_md
        "<sup>#{text}</sup>"
      end
    end
  end
end
