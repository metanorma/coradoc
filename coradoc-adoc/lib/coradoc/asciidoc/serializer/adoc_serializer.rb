# frozen_string_literal: true

# Autoload FallbackSerializer - only needed when no registered serializer is found
autoload :FallbackSerializer, 'coradoc/asciidoc/serializer/fallback_serializer'

module Coradoc
  module AsciiDoc
    module Serializer
      # Main orchestrator for serializing Coradoc models to AsciiDoc format.
      # Dispatches to appropriate serializer via ElementRegistry.
      #
      # This class is ONLY responsible for orchestration and dispatch.
      # Element registration is handled by ElementRegistry.
      class AdocSerializer
        class << self
          # Serialize a Coradoc model to AsciiDoc string
          # @param model [Coradoc::AsciiDoc::Model::Base, Array, String] Model to serialize
          # @param options [Hash] Serialization options
          # @return [String] AsciiDoc representation
          def serialize(model, options = {})
            case model
            when nil
              ''
            when String
              model
            when Array
              serialize_array(model, options)
            when Coradoc::AsciiDoc::Model::Base
              serialize_model(model, options)
            when Lutaml::Model::Serializable
              # Handle Lutaml::Model objects that have to_adoc method
              if model.respond_to?(:to_adoc)
                model.to_adoc
              else
                raise ArgumentError,
                      "Cannot serialize #{model.class.name} to AsciiDoc. " \
                      "Expected a model with #to_adoc or a registered serializer."
              end
            else
              raise ArgumentError,
                    "Unknown element type for AsciiDoc serialization: #{model.class}. " \
                    "Expected String, Array, or Coradoc::AsciiDoc::Model::Base."
            end
          end

          # Get appropriate serializer instance for a model
          # @param model [Coradoc::AsciiDoc::Model::Base] Model to serialize
          # @return [Serializers::Base] Serializer instance
          def serializer_for(model)
            # Try to find registered serializer
            if ElementRegistry.registered?(model.class)
              serializer_class = ElementRegistry.lookup(model.class)
              return serializer_class.new
            end

            # Fallback: if model has to_adoc method, use it directly
            return FallbackSerializer.new if model.respond_to?(:to_adoc)

            raise ArgumentError, "No serializer registered for #{model.class.name} and model doesn't respond to to_adoc"
          end

          private

          # Serialize an array of models
          # @param models [Array] Array of models
          # @param options [Hash] Serialization options
          # @return [String] Serialized array
          def serialize_array(models, options = {})
            results = models.map { |model| serialize(model, options) }

            # Apply spacing if needed
            if options[:apply_spacing]
              SpacingStrategy.apply(models.zip(results).map(&:first), options)
            else
              results.join
            end
          end

          # Serialize a single model
          # @param model [Coradoc::AsciiDoc::Model::Base] Model to serialize
          # @param options [Hash] Serialization options
          # @return [String] Serialized model
          def serialize_model(model, options = {})
            serializer = serializer_for(model)
            serializer.serialize(model, options)
          end
        end
      end
    end
  end
end
