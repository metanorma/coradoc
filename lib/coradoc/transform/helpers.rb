# frozen_string_literal: true

module Coradoc
  module Transform
    # Shared helper methods for model transformers
    #
    # This module provides common utilities used across different format
    # transformers (Markdown, AsciiDoc, HTML) to reduce code duplication
    # and ensure consistent behavior.
    #
    # @example Including in a transformer
    #   class MyFormat::Transform::ToCoreModel
    #     include Coradoc::Transform::Helpers
    #
    #     def transform_paragraph(para)
    #       CoreModel::Block.new(
    #         element_type: 'paragraph',
    #         content: extract_text(para.text)
    #       )
    #     end
    #   end
    #
    module Helpers
      # Extract text content from various text-like objects
      #
      # Handles nil, strings, and text objects with a content method.
      #
      # @param text [Object, nil] the text object to extract from
      # @return [String] the extracted text, or empty string if nil
      def extract_text(text)
        return '' if text.nil?
        return text.content.to_s if text.respond_to?(:content)
        return text.text.to_s if text.respond_to?(:text) && !text.is_a?(String)
        return text.to_s if text.is_a?(String)

        # For other objects without content/text methods, return empty string
        ''
      end

      # Safely convert any object to a string
      #
      # @param object [Object, nil] the object to convert
      # @return [String] the string representation, or empty string if nil
      def safe_string(object)
        return '' if object.nil?
        return object.content.to_s if object.respond_to?(:content)
        return object.text.to_s if object.respond_to?(:text) && !object.is_a?(String)

        object.to_s
      end

      # Safely convert any object to an array
      #
      # @param object [Object, nil] the object to convert
      # @return [Array] the array, or empty array if nil
      def safe_array(object)
        return [] if object.nil?
        return object if object.is_a?(Array)
        return object.to_a if object.respond_to?(:to_a)

        [object]
      end

      # Transform a collection of elements
      #
      # Maps each element through the transform method.
      # Filters out nil results by default.
      #
      # @param elements [Array, nil] the elements to transform
      # @param filter_nils [Boolean] whether to filter out nil results
      # @return [Array] the transformed elements
      def transform_collection(elements, filter_nils: true)
        result = safe_array(elements).map do |element|
          transform(element)
        end

        filter_nils ? result.compact : result
      end

      # Safely get an attribute value from an object
      #
      # @param object [Object] the object to get the attribute from
      # @param attribute [Symbol] the attribute name
      # @param default [Object] the default value if attribute is nil or missing
      # @return [Object] the attribute value or default
      def safe_attribute(object, attribute, default: nil)
        return default if object.nil?

        value = if object.respond_to?(attribute)
                  object.send(attribute)
                elsif object.respond_to?(:[])
                  object[attribute]
                else
                  default
                end

        value.nil? ? default : value
      end

      # Check if an object is a CoreModel type
      #
      # @param object [Object] the object to check
      # @return [Boolean] true if it's a CoreModel::Base subclass
      def core_model?(object)
        return false if object.nil?

        object.class.name&.start_with?('Coradoc::CoreModel::') ||
          (defined?(CoreModel::Base) && object.is_a?(CoreModel::Base))
      end

      # Check if an object is an inline element type
      #
      # @param object [Object] the object to check
      # @return [Boolean] true if it's an inline element
      def inline_element?(object)
        return false if object.nil?

        object.is_a?(CoreModel::InlineElement) if defined?(CoreModel::InlineElement)
      end

      # Check if an object is a block element type
      #
      # @param object [Object] the object to check
      # @return [Boolean] true if it's a block element
      def block_element?(object)
        return false if object.nil?

        object.is_a?(CoreModel::Block) if defined?(CoreModel::Block)
      end

      # Check if an object is a structural element type
      #
      # @param object [Object] the object to check
      # @return [Boolean] true if it's a structural element
      def structural_element?(object)
        return false if object.nil?

        object.is_a?(CoreModel::StructuralElement) if defined?(CoreModel::StructuralElement)
      end

      # Get the element type from an object
      #
      # @param element [Object] the element to check
      # @return [String, nil] the element type, or nil if not found
      def element_type(element)
        return nil if element.nil?

        return element.element_type if element.respond_to?(:element_type) && element.element_type

        return unless core_model?(element)

        class_to_element_type(element.class)
      end

      # Convert a class name to element type string
      #
      # @param klass [Class] the class to convert
      # @return [String] the element type in snake_case
      def class_to_element_type(klass)
        class_name = klass.name.to_s.split('::').last
        class_name.gsub(/([A-Z])/) { |m| "_#{m.downcase}" }.sub(/^_/, '')
      end

      # Deep transform nested content
      #
      # Recursively transforms content that may contain nested structures.
      #
      # @param content [Object, Array, nil] the content to transform
      # @return [Object, Array] the transformed content
      def deep_transform(content)
        case content
        when nil
          nil
        when Array
          content.map { |item| deep_transform(item) }
        when Hash
          content.transform_values { |v| deep_transform(v) }
        else
          transform(content)
        end
      end

      # Merge options with defaults
      #
      # @param options [Hash] the options hash
      # @param defaults [Hash] the default values
      # @return [Hash] merged options
      def merge_options(options, defaults)
        defaults.merge(options || {})
      end

      # Safely get ID from an element
      #
      # @param element [Object] the element
      # @return [String, nil] the ID, or nil if not present
      def extract_id(element)
        return nil if element.nil?

        id = if element.respond_to?(:id)
               element.id
             elsif element.respond_to?(:[])
               element[:id]
             end

        id&.to_s&.empty? ? nil : id&.to_s
      end

      # Safely get level from an element
      #
      # @param element [Object] the element
      # @param default [Integer] the default level
      # @return [Integer] the level, or default if not present
      def extract_level(element, default: 1)
        return default if element.nil?

        level = if element.respond_to?(:level)
                  element.level
                elsif element.respond_to?(:[])
                  element[:level]
                end

        level.nil? ? default : level.to_i
      end

      # Safely get language from a code block element
      #
      # @param element [Object] the code block element
      # @return [String, nil] the language, or nil if not present
      def extract_language(element)
        return nil if element.nil?

        lang = if element.respond_to?(:language)
                 element.language
               elsif element.respond_to?(:lang)
                 element.lang
               elsif element.respond_to?(:[])
                 element[:language] || element[:lang]
               end

        lang&.to_s&.empty? ? nil : lang&.to_s
      end
    end

    # Class-level helpers for transformers
    #
    # Provides class methods that can be extended by transformer classes.
    #
    # @example Using class helpers
    #   class MyTransformer
    #     extend Coradoc::Transform::ClassHelpers
    #
    #     register_transform ModelA, :transform_a
    #     register_transform ModelB, :transform_b
    #   end
    #
    module ClassHelpers
      # Get the transform registry for this class
      #
      # @return [Hash] the registry hash
      def transform_registry
        @transform_registry ||= {}
      end

      # Register a transform method for a model class
      #
      # @param model_class [Class] the model class to register for
      # @param method_name [Symbol] the method to call for transformation
      # @return [void]
      def register_transform(model_class, method_name)
        transform_registry[model_class] = method_name
      end

      # Lookup the transform method for a model
      #
      # @param model [Object] the model to find a transformer for
      # @return [Symbol, nil] the method name, or nil if not found
      def lookup_transform(model)
        model_class = model.is_a?(Class) ? model : model.class

        # Direct lookup
        method = transform_registry[model_class]
        return method if method

        # Check parent classes
        model_class.ancestors.each do |ancestor|
          next if ancestor == model_class || ancestor == Object

          method = transform_registry[ancestor]
          return method if method
        end

        nil
      end

      # Check if a transform is registered for a model
      #
      # @param model_class [Class] the class to check
      # @return [Boolean] true if registered
      def transform_registered?(model_class)
        !lookup_transform(model_class).nil?
      end

      # Clear all registered transforms
      #
      # @return [void]
      def clear_transforms
        @transform_registry = {}
      end
    end
  end
end
