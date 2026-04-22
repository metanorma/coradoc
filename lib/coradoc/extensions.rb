# frozen_string_literal: true

module Coradoc
  # Extension points for custom element types.
  #
  # This module allows users to register custom element types with their
  # own transformers, serializers, and converters. This enables extending
  # Coradoc with domain-specific or custom document elements.
  #
  # @example Register a custom element type
  #   Coradoc::Extensions.register_element(
  #     :callout,
  #     model_class: MyCalloutElement,
  #     transformers: {
  #       to_html: MyCalloutHtmlConverter,
  #       to_adoc: MyCalloutAdocSerializer
  #     }
  #   )
  #
  # @example Check if a custom element is registered
  #   Coradoc::Extensions.registered?(:callout)
  #
  # @example Get all custom element types
  #   Coradoc::Extensions.element_types
  #
  module Extensions
    # Represents a registered custom element type
    class CustomElement
      attr_reader :name, :model_class, :transformers, :serializers, :options

      # Create a new custom element registration
      #
      # @param name [Symbol] The element type name
      # @param model_class [Class] The model class for this element
      # @param transformers [Hash] Hash of format => transformer class
      # @param serializers [Hash] Hash of format => serializer class
      # @param options [Hash] Additional options
      def initialize(name, model_class:, transformers: {}, serializers: {}, **options)
        @name = name.to_sym
        @model_class = model_class
        @transformers = transformers.transform_keys(&:to_sym)
        @serializers = serializers.transform_keys(&:to_sym)
        @options = options
      end

      # Check if this element has a transformer for a format
      #
      # @param format [Symbol] The target format
      # @return [Boolean]
      def has_transformer?(format)
        transformers.key?(format.to_sym)
      end

      # Check if this element has a serializer for a format
      #
      # @param format [Symbol] The target format
      # @return [Boolean]
      def has_serializer?(format)
        serializers.key?(format.to_sym)
      end

      # Get transformer for a format
      #
      # @param format [Symbol] The target format
      # @return [Class, nil] The transformer class
      def transformer(format)
        transformers[format.to_sym]
      end

      # Get serializer for a format
      #
      # @param format [Symbol] The target format
      # @return [Class, nil] The serializer class
      def serializer(format)
        serializers[format.to_sym]
      end
    end

    class << self
      # Register a custom element type.
      #
      # @param name [Symbol] The element type name (must be unique)
      # @param model_class [Class] The model class for this element
      # @param transformers [Hash] Hash of format => transformer class
      # @param serializers [Hash] Hash of format => serializer class
      # @param options [Hash] Additional options (priority, description, etc.)
      # @return [CustomElement] The registered element
      # @raise [ArgumentError] If name already registered or missing required params
      #
      # @example
      #   Coradoc::Extensions.register_element(
      #     :callout,
      #     model_class: CalloutElement,
      #     transformers: {
      #       html: CalloutHtmlTransformer,
      #       adoc: CalloutAdocTransformer
      #     },
      #     serializers: {
      #       html: CalloutHtmlSerializer,
      #       adoc: CalloutAdocSerializer
      #     },
      #     description: "Callout box element"
      #   )
      def register_element(name, model_class:, transformers: {}, serializers: {}, **options)
        # Validate name before converting to symbol
        raise ArgumentError, 'Element name is required' if name.nil?
        raise ArgumentError, 'Element name cannot be empty' if name.to_s.empty?
        raise ArgumentError, 'Model class is required' if model_class.nil?

        name = name.to_sym

        if elements.key?(name)
          raise ArgumentError, "Element '#{name}' is already registered. " \
                               'Use unregister_element first to replace it.'
        end

        element = CustomElement.new(
          name,
          model_class: model_class,
          transformers: transformers,
          serializers: serializers,
          **options
        )

        elements[name] = element
        register_with_transformers(element) if element.transformers.any?

        element
      end

      # Unregister a custom element type.
      #
      # @param name [Symbol] The element type name
      # @return [Boolean] true if element was removed
      def unregister_element(name)
        name = name.to_sym
        !!elements.delete(name)
      end

      # Check if a custom element is registered.
      #
      # @param name [Symbol] The element type name
      # @return [Boolean]
      def registered?(name)
        elements.key?(name.to_sym)
      end

      # Get a registered custom element.
      #
      # @param name [Symbol] The element type name
      # @return [CustomElement, nil]
      def get(name)
        elements[name.to_sym]
      end

      # List all registered custom element types.
      #
      # @return [Array<Symbol>]
      def element_types
        elements.keys
      end

      # Get all registered elements.
      #
      # @return [Hash<Symbol, CustomElement>]
      def all_elements
        elements.dup
      end

      # Clear all registered elements.
      #
      # @return [Integer] Number of elements removed
      def clear_all
        count = elements.size
        @elements = {}
        count
      end

      # Register a transformer for an existing element type.
      #
      # @param element_name [Symbol] The element type name
      # @param format [Symbol] The target format
      # @param transformer_class [Class] The transformer class
      # @return [Boolean] true if successful
      def add_transformer(element_name, format, transformer_class)
        element = get(element_name)
        return false unless element

        element.transformers[format.to_sym] = transformer_class
        register_transformer_with_format(format, element.model_class, transformer_class)
        true
      end

      # Register a serializer for an existing element type.
      #
      # @param element_name [Symbol] The element type name
      # @param format [Symbol] The target format
      # @param serializer_class [Class] The serializer class
      # @return [Boolean] true if successful
      def add_serializer(element_name, format, serializer_class)
        element = get(element_name)
        return false unless element

        element.serializers[format.to_sym] = serializer_class
        true
      end

      # Find the appropriate transformer for a model class.
      #
      # @param model [Object] The model instance or class
      # @param format [Symbol] The target format
      # @return [Class, nil] The transformer class
      def find_transformer(model, format)
        model_class = model.is_a?(Class) ? model : model.class

        elements.each_value do |element|
          return element.transformer(format) if element.model_class == model_class && element.has_transformer?(format)
        end

        nil
      end

      # Find the appropriate serializer for a model class.
      #
      # @param model [Object] The model instance or class
      # @param format [Symbol] The target format
      # @return [Class, nil] The serializer class
      def find_serializer(model, format)
        model_class = model.is_a?(Class) ? model : model.class

        elements.each_value do |element|
          return element.serializer(format) if element.model_class == model_class && element.has_serializer?(format)
        end

        nil
      end

      private

      def elements
        @elements ||= {}
      end

      def validate_element_registration!(name, model_class)
        # Check name first before calling to_sym
        raise ArgumentError, 'Element name is required' if name.nil? || (name.respond_to?(:to_s) && name.to_s.empty?)
        raise ArgumentError, 'Model class is required' if model_class.nil?

        name = name.to_sym
        return unless elements.key?(name)

        raise ArgumentError, "Element '#{name}' is already registered. " \
                             'Use unregister_element first to replace it.'
      end

      def register_with_transformers(element)
        element.transformers.each do |format, transformer_class|
          register_transformer_with_format(format, element.model_class, transformer_class)
        end
      end

      def register_transformer_with_format(format, model_class, transformer_class)
        # Try to register with the format's transformer registry if available
        format_module = Coradoc.get_format(format)
        return unless format_module

        if format_module.respond_to?(:register_transformer)
          format_module.register_transformer(model_class,
                                             transformer_class)
        end
      rescue StandardError => e
        Logger.warn("Failed to register transformer for #{format}: #{e.message}")
      end
    end
  end
end
