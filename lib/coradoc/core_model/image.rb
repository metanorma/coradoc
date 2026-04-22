# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Represents an image in a document
    #
    # Images can be block-level (standalone) or inline. They support
    # various attributes like alt text, dimensions, and linking.
    #
    # @example Creating a block image
    #   image = CoreModel::Image.new(
    #     src: "images/diagram.png",
    #     alt: "System Architecture",
    #     caption: "Figure 1: System Overview",
    #     width: "800px"
    #   )
    #
    # @example Creating an inline image
    #   icon = CoreModel::Image.new(
    #     src: "icons/warning.png",
    #     alt: "Warning",
    #     inline: true
    #   )
    class Image < Base
      # @!attribute src
      #   @return [String, nil] source URL or path to the image
      attribute :src, :string

      # @!attribute alt
      #   @return [String, nil] alternative text for accessibility
      attribute :alt, :string

      # @!attribute caption
      #   @return [String, nil] caption text for the image
      attribute :caption, :string

      # @!attribute width
      #   @return [String, nil] image width (e.g., '100%', '500px')
      attribute :width, :string

      # @!attribute height
      #   @return [String, nil] image height (e.g., '300px', 'auto')
      attribute :height, :string

      # @!attribute link
      #   @return [String, nil] URL to link to when image is clicked
      attribute :link, :string

      # @!attribute inline
      #   @return [Boolean] whether this is an inline image
      attribute :inline, :boolean, default: -> { false }

      # @!attribute float
      #   @return [String, nil] float position ('left', 'right')
      attribute :float, :string

      private

      def comparable_attributes
        super + %i[src alt caption width height link inline]
      end
    end
  end
end
