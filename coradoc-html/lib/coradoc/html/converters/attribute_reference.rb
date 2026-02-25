# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converts CoreModel::InlineElement with format_type "attribute_reference"
      #
      # Attribute references are inline placeholders that reference document attributes
      # (e.g., {author}, {docname}, {revnumber}).
      #
      # In HTML, we render them as-is with the curly braces to preserve the
      # reference syntax. Actual substitution of attribute values would happen
      # at a different processing layer if needed.
      #
      # Examples:
      #   {author}    => {author}
      #   {docname}   => {docname}
      class AttributeReference < Base
        # Convert CoreModel::InlineElement (attribute_reference) to HTML
        #
        # @param model [Coradoc::CoreModel::InlineElement] the attribute reference model
        # @param options [Hash] conversion options
        # @option options [Hash] :document_attributes Document attributes for substitution
        # @return [String] HTML representation of the attribute reference
        def self.to_html(model, options = {})
          name = model.target.to_s

          # Try to substitute with actual attribute value if document_attributes provided
          if options[:document_attributes]
            value = options[:document_attributes][name] || options[:document_attributes][name]
            return escape_html(value.to_s) if value
          end

          # Fallback: render as-is with curly braces
          escape_html("{#{name}}")
        end

        # Convert HTML text to CoreModel::InlineElement (attribute_reference)
        #
        # @param text [String] the HTML text
        # @param _options [Hash] conversion options (unused)
        # @return [Coradoc::CoreModel::InlineElement, nil] the attribute reference model or nil
        def self.to_coradoc(text, _options = {})
          return nil unless text.is_a?(String)

          # Match attribute reference pattern: {name}
          match = text.match(/^\{([^}]+)\}$/)
          return nil unless match

          name = match[1]

          Coradoc::CoreModel::InlineElement.new(
            format_type: 'attribute_reference',
            target: name
          )
        end
      end
    end
  end
end
