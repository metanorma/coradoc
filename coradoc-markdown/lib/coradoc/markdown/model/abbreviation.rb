# frozen_string_literal: true

module Coradoc
  module Markdown
    # Abbreviation model representing an abbreviation definition.
    #
    # Kramdown syntax:
    # `*[ABC]: A Big Corporation`
    #
    # When the abbreviation appears in the text, it will be wrapped
    # with an <abbr> tag with the definition as the title.
    #
    # @example Abbreviation definition
    #   abbr = Coradoc::Markdown::Abbreviation.new(
    #     term: "ABC",
    #     definition: "A Big Corporation"
    #   )
    #
    class Abbreviation < Base
      # The abbreviation term
      attribute :term, :string

      # The full definition/explanation
      attribute :definition, :string
    end
  end
end
