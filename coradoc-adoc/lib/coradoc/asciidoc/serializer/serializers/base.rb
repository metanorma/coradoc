# frozen_string_literal: true

require 'coradoc/asciidoc/serializer/serialization_context'

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        # Base serializer class for converting Coradoc models to AsciiDoc format.
        # Provides common serialization infrastructure and helpers.
        # Each model type should have its own serializer that inherits from this.
        class Base
          # Serialize a Coradoc model to AsciiDoc string
          # @param model [Coradoc::AsciiDoc::Model::Base] The model to serialize
          # @param options_or_context [Hash, SerializationContext] Options or context
          # @return [String] AsciiDoc representation
          def serialize(model, options_or_context = {})
            return '' if model.nil?

            context = SerializationContext.from_options(options_or_context)
            to_adoc(model, context)
          end

          # Abstract method to be implemented by subclasses
          # @param model [Coradoc::AsciiDoc::Model::Base] The model to convert
          # @param options_or_context [Hash, SerializationContext] Options or context
          # @return [String] AsciiDoc representation
          def to_adoc(_model, options_or_context = {})
            SerializationContext.from_options(options_or_context)
            raise NotImplementedError,
                  "#{self.class.name} must implement #to_adoc"
          end

          protected

          # Normalize options_or_context to SerializationContext
          # @param options_or_context [Hash, SerializationContext] Options or context
          # @return [SerializationContext] Serialization context
          def normalize_context(options_or_context)
            SerializationContext.from_options(options_or_context)
          end

          # Serialize child elements of a model
          # @param children [Array, Object] Child elements to serialize
          # @param options_or_context [Hash, SerializationContext] Options or context
          # @return [String] Serialized children
          def serialize_children(children, options_or_context = {})
            context = normalize_context(options_or_context)

            case children
            when Array
              return '' if children.empty?

              # Mark the last child as the last element for proper spacing
              children.each_with_index.map do |child, index|
                child_context = context.for_child(index, children.length)
                serialize_child(child, child_context)
              end.join
            when nil
              ''
            else
              serialize_child(children, context)
            end
          end

          # Serialize a single child element
          # @param child [Object] Child element to serialize
          # @param options_or_context [Hash, SerializationContext] Options or context
          # @return [String] Serialized child
          def serialize_child(child, options_or_context = {})
            return '' if child.nil?

            context = normalize_context(options_or_context)

            case child
            when String
              child
            when Coradoc::AsciiDoc::Model::Base
              # Use AdocSerializer for all Coradoc models
              AdocSerializer.serialize(child, context)
            when Lutaml::Model::Serializable
              # Handle Lutaml::Model::Serializable objects (like CrossReference, Term)
              # These are model objects that need proper serialization
              AdocSerializer.serialize(child, context)
            when Proc
              child.call
            else
              # Handle objects that respond to to_adoc (like test doubles)
              if child.respond_to?(:to_adoc)
                # For non-Coradoc objects, call to_adoc without arguments
                # Test doubles and external objects typically don't accept context
                child.to_adoc
              else
                # This is a programming error - we received an unexpected type
                raise ArgumentError,
                      "Cannot serialize child of type #{child.class.name}. " \
                      'Expected String, Coradoc::AsciiDoc::Model::Base, ' \
                      'Lutaml::Model::Serializable, or Proc. ' \
                      "Got: #{child.inspect[0..100]}"
              end
            end
          end

          # Preserve model structure during serialization (recursive)
          # This method handles nested inline models by recursively serializing
          # them, unlike serialize_children which flattens to strings.
          # @param content [Array, String, Object] Content to serialize
          # @return [String] Serialized content with structure preserved
          def serialize_content(content)
            case content
            when Array
              content.map { |elem| serialize_content(elem) }.join
            when String
              content
            when nil
              ''
            else
              # Try AdocSerializer first for Lutaml models
              if content.is_a?(Lutaml::Model::Serializable) || content.is_a?(Coradoc::AsciiDoc::Model::Base)
                AdocSerializer.serialize(content)
              # Fall back to to_adoc if available
              elsif content.respond_to?(:to_adoc)
                content.to_adoc
              else
                # This is a programming error - we received an unexpected type
                raise ArgumentError,
                      "Cannot serialize content of type #{content.class.name}. " \
                      'Expected String, nil, Array, or serializable object. ' \
                      "Got: #{content.inspect[0..100]}"
              end
            end
          end

          # Helper to check if element is block-level
          # @param element [Object] Element to check
          # @return [Boolean] True if block-level
          def block_level_element?(element)
            element.is_a?(Coradoc::AsciiDoc::Model::Block::Core) ||
              element.is_a?(Coradoc::AsciiDoc::Model::Section) ||
              element.is_a?(Coradoc::AsciiDoc::Model::Paragraph) ||
              element.is_a?(Coradoc::AsciiDoc::Model::List) ||
              element.is_a?(Coradoc::AsciiDoc::Model::Table)
          end

          # Helper to add spacing between elements
          # @param elements [Array] Elements to space
          # @param options [Hash] Spacing options
          # @return [String] Elements with spacing
          def add_spacing(elements, options = {})
            SpacingStrategy.apply(elements, options)
          end

          # Helper to format attribute list
          # @param attrs [Coradoc::AsciiDoc::Model::AttributeList] Attribute list
          # @return [String] Formatted attribute list
          def format_attribute_list(attrs)
            return '' if attrs.nil?

            Formatter.attribute_list(attrs)
          end

          # Helper to format block attributes
          # @param model [Coradoc::AsciiDoc::Model::Base] Model with attributes
          # @return [String] Formatted block attributes
          def format_block_attributes(model)
            return '' unless model.respond_to?(:attributes) &&
                             model.attributes

            Formatter.block_attributes(model.attributes)
          end
        end
      end
    end
  end
end
