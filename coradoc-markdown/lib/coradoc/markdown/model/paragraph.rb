# frozen_string_literal: true

module Coradoc
  module Markdown
    # Paragraph model representing a Markdown paragraph.
    #
    # @example Create a paragraph
    #   para = Coradoc::Markdown::Paragraph.new(text: "Hello World")
    #
    class Paragraph < Base
      attribute :text, :string
      attribute :children, Base, collection: true, default: []
    end
  end
end
