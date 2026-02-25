# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      # Registry for mapping Coradoc model classes to their AsciiDoc serializers.
      # This is the authoritative source for model→serializer mappings.
      #
      # Pattern mirrors Input::Html::Converters registry for symmetry.
      #
      # @example Registering a custom serializer
      #   ElementRegistry.override(Model::Paragraph, CustomParagraphSerializer)
      #
      # @example Wrapping an existing serializer
      #   original = ElementRegistry.get(Model::Paragraph)
      #   ElementRegistry.override(Model::Paragraph, WrapperSerializer.new(original))
      class ElementRegistry
        class << self
          # Register a serializer for a model class
          # @param model_class [Class] The Coradoc model class
          # @param serializer_class [Class] The serializer class
          def register(model_class, serializer_class)
            registry[model_class] = serializer_class
          end

          # Override a serializer for a model class
          # This is an alias for register that makes the intent explicit
          # @param model_class [Class] The Coradoc model class
          # @param serializer_class [Class] The new serializer class
          # @return [Class, nil] The previous serializer class, or nil if none
          def override(model_class, serializer_class)
            previous = registry[model_class]
            registry[model_class] = serializer_class
            previous
          end

          # Unregister a serializer for a model class
          # @param model_class [Class] The model class to unregister
          # @return [Class, nil] The removed serializer class, or nil if none
          def unregister(model_class)
            registry.delete(model_class)
          end

          # Get the serializer for a model class without raising
          # @param model_class [Class] The model class
          # @return [Class, nil] The serializer class, or nil if not registered
          def get(model_class)
            registry[model_class]
          end

          # Lookup serializer for a model class
          # @param model_class [Class] The model class
          # @return [Class] The serializer class
          # @raise [ArgumentError] If no serializer is registered
          def lookup(model_class)
            serializer_class = registry[model_class]

            unless serializer_class
              raise ArgumentError,
                    "No serializer registered for #{model_class.name}. " \
                    'Please register a serializer in ElementRegistry, or the serializer ' \
                    'may not have been loaded yet (check Registrations.load_all!)'
            end

            serializer_class
          end

          # Get all registered model classes
          # @return [Array<Class>] Array of registered model classes
          def registered_models
            registry.keys
          end

          # Check if a model class has a registered serializer
          # @param model_class [Class] The model class
          # @return [Boolean] True if registered
          def registered?(model_class)
            registry.key?(model_class)
          end

          # Clear all registrations (mainly for testing)
          def clear!
            registry.clear
          end

          # Get the registry hash
          # @return [Hash] Model class => Serializer class mapping
          def registry
            @@registry ||= {}
          end
        end
      end
    end
  end
end
