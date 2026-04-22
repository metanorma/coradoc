# frozen_string_literal: true

module Coradoc
  module Markdown
    # Image model representing a Markdown image ![alt](src).
    #
    # @example Create an image
    #   img = Coradoc::Markdown::Image.new(
    #     alt: "Logo",
    #     src: "/images/logo.png"
    #   )
    #
    class Image < Base
      attribute :alt, :string
      attribute :src, :string
      attribute :title, :string # Optional title
    end
  end
end
