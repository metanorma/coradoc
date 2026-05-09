# frozen_string_literal: true


module Coradoc
  module Markdown
    # Represents strikethrough text using GFM ~~ syntax.
    #
    # Example: ~~deleted text~~
    #
    class Strikethrough < Base
      attribute :text, :string

      def to_md
        "~~#{text}~~"
      end
    end
  end
end
