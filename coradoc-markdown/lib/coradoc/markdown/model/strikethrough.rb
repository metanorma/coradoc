# frozen_string_literal: true

module Coradoc
  module Markdown
    # Represents strikethrough text using GFM ~~ syntax.
    #
    # Example: ~~deleted text~~
    #
    class Strikethrough < Base
      attribute :text, :string
    end
  end
end
