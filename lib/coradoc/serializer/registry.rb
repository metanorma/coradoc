# frozen_string_literal: true

module Coradoc
  module Serializer
    # Registry for document element serializers
    #
    # Provides a registry-based pattern for looking up serializers
    # for document element types. This allows users to register
    # custom serializers for their own element types or override
    # existing serializers.
    #
    # @example Registering a custom serializer
    #   Coradoc::Serializer::Registry.register(MyCustomElement, MyCustomSerializer)
    #
    # @example Looking up a serializer
    #   serializer = Coradoc::Serializer::Registry.lookup(element)
    #   output = serializer.serialize(element) if serializer
    #
    class Registry
      class << self
        # Get the global registry instance
        #
        # @return [Hash] the registry hash
        def registry
          @registry ||= {}
        end

        # Register a serializer for a model class
        #
        # @param model_class [Class] The model class to serialize
        # @param serializer_class [Class] The serializer class to use
        # @return [Class, nil] The previous serializer class, if any
        def register(model_class, serializer_class)
          key = class_key(model_class)
          previous = registry[key]
          registry[key] = serializer_class
          previous
        end

        # Unregister a serializer for a model class
        #
        # @param model_class [Class] The model class to unregister
        # @return [Class, nil] The removed serializer class, if any
        def unregister(model_class)
          key = class_key(model_class)
          registry.delete(key)
        end

        # Look up a serializer for a model instance or class
        #
        # @param model [Object, Class] The model instance or class
        # @return [Class, nil] The serializer class, or nil if not found
        def lookup(model)
          model_class = model.is_a?(Class) ? model : model.class
          key = class_key(model_class)

          # Direct lookup
          return registry[key] if registry.key?(key)

          # Try parent classes
          model_class.ancestors.each do |ancestor|
            next if ancestor == model_class || ancestor == Object

            ancestor_key = class_key(ancestor)
            return registry[ancestor_key] if registry.key?(ancestor_key)
          end

          nil
        end

        # Check if a serializer is registered for a model
        #
        # @param model [Object, Class] The model instance or class
        # @return [Boolean] true if a serializer is registered
        def registered?(model)
          !lookup(model).nil?
        end

        # Get all registered model classes
        #
        # @return [Array<Class>] Array of registered model classes
        def registered_models
          registry.keys
        end

        # Clear all registered serializers
        #
        # @return [Hash] Empty registry
        def clear
          @registry = {}
        end

        # Serialize a model using its registered serializer
        #
        # @param model [Object] The model to serialize
        # @param format [Symbol] The output format (:adoc, :html, :md, etc.)
        # @param options [Hash] Additional serialization options
        # @return [String, nil] The serialized output, or nil if no serializer found
        def serialize(model, format: :adoc, **options)
          serializer_class = lookup(model)
          return nil unless serializer_class

          serializer = serializer_class.respond_to?(:new) ? serializer_class.new : serializer_class

          if serializer.respond_to?(:serialize)
            serializer.serialize(model, format: format, **options)
          elsif serializer.respond_to?(:to_s)
            serializer.to_s
          else
            model.to_s
          end
        end

        private

        # Generate a registry key for a class
        def class_key(klass)
          klass.name.to_s
        end
      end
    end

    # Base class for element serializers
    #
    # Provides a common interface for all serializers.
    # Subclasses should implement #serialize method.
    #
    # @example Creating a custom serializer
    #   class MyElementSerializer < Coradoc::Serializer::Base
    #     def serialize(element, format: :adoc, **options)
    #       "Custom: #{element.text}"
    #     end
    #   end
    #
    class Base
      # Serialize an element to the target format
      #
      # @param element [Object] The element to serialize
      # @param format [Symbol] The output format
      # @param options [Hash] Additional options
      # @return [String] The serialized output
      def serialize(element, format: :adoc, **_options)
        element.to_s
      end

      # Class method for serialization
      def self.serialize(element, **options)
        new.serialize(element, **options)
      end
    end
  end
end
