# frozen_string_literal: true

module Coradoc
  module Markdown
    # Heading model representing a Markdown heading (# to ######).
    #
    # @example Create a heading
    #   heading = Coradoc::Markdown::Heading.new(level: 1, text: "Title")
    #
    class Heading < Base
      attribute :level, :integer, default: 1
      attribute :text, :string

      def initialize(level: 1, text: '')
        super()
        @level = level
        @text = text
      end

      # Generate an auto ID from the heading text
      #
      # @return [String] A slugified version of the text suitable for use as an ID
      # @example
      #   Heading.new(text: "Hello World!").auto_id #=> "hello-world"
      def auto_id
        return '' if text.nil? || text.empty?

        # Downcase, replace non-alphanumeric with hyphens, collapse multiple hyphens
        slug = text.to_s
                   .downcase
                   .gsub(/[^a-z0-9]+/, '-')
                   .gsub(/^-+|-+$/, '')
        slug.empty? ? 'section' : slug
      end

      # Get the ID for this heading (uses explicit id if set, otherwise auto_id)
      #
      # @return [String] The ID to use for this heading
      def heading_id
        id || auto_id
      end
    end
  end
end
