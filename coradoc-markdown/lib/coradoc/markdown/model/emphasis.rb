# frozen_string_literal: true

module Coradoc
  module Markdown
    # Emphasis model representing italic text (*text* or _text_).
    #
    class Emphasis < Base
      attribute :text, :string
    end
  end
end
