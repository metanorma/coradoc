# frozen_string_literal: true

module Coradoc
  module Markdown
    # Represents highlighted text using == syntax (extended Markdown).
    #
    # Example: ==highlighted text==
    #
    class Highlight < Base
      attribute :text, :string
    end
  end
end
