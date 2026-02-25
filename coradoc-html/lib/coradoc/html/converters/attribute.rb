# frozen_string_literal: true

require 'nokogiri'

module Coradoc
  module Html
    module Converters
      # Converts document attributes to/from HTML
      #
      # Attributes are document-level directives (e.g., :author:, :toc:).
      # In HTML, we represent them as HTML comments to preserve the attribute
      # information without affecting the rendered output.
      #
      # Examples:
      #   :author: John Doe  => <!-- :author: John Doe -->
      #   :toc:              => <!-- :toc: -->
      class Attribute
        # Convert CoreModel::Block (attribute) to HTML comment
        def self.to_html(model, _options = {})
          key = model.metadata&.dig(:key).to_s
          key = escape_html(key)

          # Handle single value or array of values
          values = Array(model.metadata&.dig(:value)).compact

          if values.empty?
            # Attribute with no value (e.g., :toc:)
            "<!-- :#{key}: -->"
          else
            # Attribute with value(s)
            value_str = values.map { |v| escape_html(v.to_s) }.join(', ')
            "<!-- :#{key}: #{value_str} -->"
          end
        end

        # Convert HTML comment to CoreModel::Block (attribute)
        def self.to_coradoc(element, _options = {})
          return nil unless element.is_a?(Nokogiri::XML::Comment)

          content = element.content.strip

          # Match attribute pattern: :key: or :key: value
          return nil unless content.match?(/^:([^:]+):(.*)$/)

          match = content.match(/^:([^:]+):(.*)$/)
          key = match[1].strip
          value_part = match[2].strip

          # Parse value(s) - could be comma-separated
          values = if value_part.empty?
                     []
                   else
                     value_part.split(',').map(&:strip)
                   end

          Coradoc::CoreModel::Block.new(
            element_type: 'attribute',
            content: key,
            metadata: {
              key: key,
              value: values
            }
          )
        end
      end
    end
  end
end
