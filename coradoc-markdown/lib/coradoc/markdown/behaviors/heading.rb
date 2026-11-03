# frozen_string_literal: true

module Coradoc
  module Markdown
    module Behaviors
      # Hand-written behavior for Heading, shared by the hand-written and
      # the schema-generated class.
      module Heading
        # Generate an auto ID from the heading text
        #
        # @return [String] A slugified version of the text suitable for use as an ID
        # @example
        #   Heading.new(text: "Hello World!").auto_id #=> "hello-world"
        def auto_id
          return '' if text.nil? || text.empty?

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
end
