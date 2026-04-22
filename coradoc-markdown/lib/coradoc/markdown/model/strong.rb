# frozen_string_literal: true

module Coradoc
  module Markdown
    # Strong model representing bold text (**text** or __text__).
    #
    class Strong < Base
      attribute :text, :string
    end
  end
end
