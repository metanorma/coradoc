# frozen_string_literal: true

module Coradoc
  module Html
    # Base module for HTML processing utilities
    module Base
      class << self
        # Convert content to HTML, handling various input types
        def convert_content(content, state = {})
          return '' if content.nil?

          case content
          when String
            return '' if content.empty?

            escape_html(content)
          when Array
            return '' if content.empty?

            content.map { |item| convert_content(item, state) }.join
          else
            # If content responds to a converter, use it
            converter = find_converter(content.class)
            if converter
              converter.to_html(content, state)
            else
              content.to_s
            end
          end
        end

        # Find the appropriate converter for a model class
        def find_converter(model_class)
          return nil unless defined?(Coradoc::Html::Converters)

          converter_name = model_class.name.split('::').last

          # Use const_get on the Converters module to trigger autoload
          begin
            klass = Coradoc::Html::Converters.const_get(converter_name, false)
            # Return nil if this is the Base class itself (not a real converter)
            # or if it doesn't inherit from Converters::Base
            return nil if klass == Coradoc::Html::Converters::Base
            return nil unless klass <= Coradoc::Html::Converters::Base

            klass
          rescue NameError
            nil
          end
        end

        # Escape HTML special characters
        def escape_html(text)
          return '' if text.nil?
          return text unless text.is_a?(String)

          text
            .gsub('&', '&amp;')
            .gsub('<', '&lt;')
            .gsub('>', '&gt;')
            .gsub('"', '&quot;')
            .gsub("'", '&#39;')
        end

        # Unescape HTML entities
        def unescape_html(text)
          return '' if text.nil?
          return text unless text.is_a?(String)

          text
            .gsub('&amp;', '&')
            .gsub('&lt;', '<')
            .gsub('&gt;', '>')
            .gsub('&quot;', '"')
            .gsub('&#39;', "'")
            .gsub('&#x27;', "'")
        end

        # Build HTML element with attributes
        def build_element(tag, content = nil, attributes = {})
          attrs = build_attributes(attributes)
          attr_string = attrs.empty? ? '' : " #{attrs}"

          # Handle empty content (String, Array, or nil)
          content_empty = case content
                          when nil, String, Array
                            content.nil? || content.empty?
                          else
                            false
                          end

          if content_empty
            # Self-closing for void elements
            if void_element?(tag)
              "<#{tag}#{attr_string}>"
            else
              "<#{tag}#{attr_string}></#{tag}>"
            end
          else
            "<#{tag}#{attr_string}>#{content}</#{tag}>"
          end
        end

        # Build HTML attributes string
        def build_attributes(attributes)
          return '' if attributes.nil? || attributes.empty?

          attributes.map do |key, value|
            next if value.nil?

            escaped_value = escape_html(value.to_s)
            %(#{key}="#{escaped_value}")
          end.compact.join(' ')
        end

        # Check if element is a void element (self-closing)
        def void_element?(tag)
          %w[area base br col embed hr img input link meta param source track wbr].include?(tag.to_s)
        end

        # Extract attributes from a CoreModel
        #
        # @param model [Coradoc::CoreModel::Base] Model to extract attributes from
        # @return [Hash] Attributes hash
        def extract_attributes(model)
          attrs = {}

          # Extract ID if available
          attrs[:id] = model.id if model.respond_to?(:id) && model.id

          # Extract title if available
          attrs[:title] = model.title if model.respond_to?(:title) && model.title

          # Extract class/role if available
          if model.respond_to?(:metadata) && model.metadata
            attrs[:class] = model.metadata[:class] || model.metadata[:role]
            attrs.merge!(model.metadata.except(:class, :role))
          end

          attrs
        end

        # Wrap content with line breaks if needed
        def wrap_lines(content)
          return content unless content.is_a?(String)

          content.split("\n").join("<br>\n")
        end

        # Process children of a node (common operation)
        def treat_children(children, state = {})
          return [] if children.nil? || children.empty?

          Array(children).map do |child|
            convert_content(child, state)
          end
        end
      end
    end
  end
end
