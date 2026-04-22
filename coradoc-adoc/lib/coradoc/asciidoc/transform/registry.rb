# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      # Registry for model transformers
      #
      # Provides a flexible, extensible way to register and lookup transformers
      # that convert between different model types. This replaces case statements
      # with a registry pattern, following the Open/Closed Principle.
      #
      # @example Register a transformer
      #   Coradoc::AsciiDoc::Transform::Registry.register(
      #     Coradoc::AsciiDoc::Model::Document,
      #     ->(model) { transform_document(model) }
      #   )
      #
      # @example Lookup and apply a transformer
      #   transformer = Coradoc::AsciiDoc::Transform::Registry.lookup(model.class)
      #   result = transformer.call(model) if transformer
      #
      class Registry
        class << self
          # Get the global registry instance
          #
          # @return [Hash] the registry hash
          def registry
            @registry ||= {}
          end

          # Register a transformer for a source class
          #
          # @param source_class [Class] the source model class
          # @param transformer [#call] a callable that transforms the model
          # @param target_class [Class, nil] optional target class for bidirectional lookup
          # @return [void]
          def register(source_class, transformer, target_class: nil)
            registry[source_class] = transformer

            # Store reverse mapping if target class specified
            return unless target_class

            reverse_registry[target_class] = transformer
          end

          # Register a transformer with a priority
          #
          # Higher priority transformers are checked first.
          # This is useful for handling subclasses before parent classes.
          #
          # @param source_class [Class] the source model class
          # @param transformer [#call] a callable that transforms the model
          # @param priority [Integer] priority level (higher = checked first)
          # @return [void]
          def register_with_priority(source_class, transformer, priority: 0)
            @prioritized_registry ||= []
            @prioritized_registry << {
              class: source_class,
              transformer: transformer,
              priority: priority
            }
            # Sort by priority descending
            @prioritized_registry.sort_by! { |e| -e[:priority] }
          end

          # Lookup a transformer for a model
          #
          # First checks exact class match, then checks prioritized registry,
          # then walks up the inheritance chain.
          #
          # @param model_class [Class] the model class to find a transformer for
          # @return [#call, nil] the transformer or nil if not found
          def lookup(model_class)
            # 1. Check exact match in main registry
            return registry[model_class] if registry.key?(model_class)

            # 2. Check prioritized registry
            if @prioritized_registry
              entry = @prioritized_registry.find { |e| model_class <= e[:class] }
              return entry[:transformer] if entry
            end

            # 3. Walk up inheritance chain
            model_class.ancestors.each do |ancestor|
              next if ancestor == model_class
              next if [Object, BasicObject].include?(ancestor)

              return registry[ancestor] if registry.key?(ancestor)
            end

            nil
          end

          # Transform a model using the registered transformer
          #
          # @param model [Object] the model to transform
          # @return [Object] the transformed model
          # @raise [ArgumentError] if no transformer is registered
          def transform(model)
            return model if model.nil?

            # Handle arrays specially
            return model.map { |item| transform(item) } if model.is_a?(Array)

            transformer = lookup(model.class)
            if transformer
              transformer.call(model)
            else
              # Return unchanged if no transformer found
              model
            end
          end

          # Check if a transformer is registered for a class
          #
          # @param model_class [Class] the class to check
          # @return [Boolean]
          def registered?(model_class)
            !lookup(model_class).nil?
          end

          # Clear all registrations (useful for testing)
          #
          # @return [void]
          def clear
            registry.clear
            @prioritized_registry = nil
          end

          # Get all registered source classes
          #
          # @return [Array<Class>]
          def registered_classes
            registry.keys
          end

          private

          def reverse_registry
            @reverse_registry ||= {}
          end
        end
      end
    end
  end
end
