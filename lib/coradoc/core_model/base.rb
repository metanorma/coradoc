# frozen_string_literal: true

require 'lutaml/model'

module Coradoc
  module CoreModel
    # Base class for all core models
    #
    # Provides common functionality for schema-agnostic document models.
    # This class establishes the foundational structure for all CoreModel
    # classes, including semantic equivalence comparison and common
    # attributes.
    #
    # @example Creating a base model
    #   model = CoreModel::Base.new(
    #     id: "example-1",
    #     title: "Example Title",
    #     element_attributes: [
    #       CoreModel::ElementAttribute.new(name: "role", value: "note")
    #     ]
    #   )
    #
    # @example Semantic comparison
    #   model1 = CoreModel::Base.new(id: "test", title: "Test")
    #   model2 = CoreModel::Base.new(id: "test", title: "Test")
    #   model1.semantically_equivalent?(model2) # => true
    class Base < Lutaml::Model::Serializable
      # @!attribute id
      #   @return [String, nil] unique identifier for the element
      attribute :id, :string

      # @!attribute title
      #   @return [String, nil] title of the element
      attribute :title, :string

      # @!attribute element_attributes
      #   @return [Array<ElementAttribute>] collection of element attributes
      attribute :element_attributes, ElementAttribute, collection: true

      # @!attribute metadata_entries
      #   @return [Array<MetadataEntry>] additional metadata entries
      attribute :metadata_entries, MetadataEntry, collection: true

      # Get all metadata as a hash, or a specific metadata value by key
      # @overload metadata
      #   @return [Hash] All metadata as key-value pairs
      # @overload metadata(key)
      #   @param key [String] The metadata key
      #   @return [String, nil] The value or nil
      def metadata(key = nil)
        entries = metadata_entries || []
        if key.nil?
          # Return all metadata as hash
          entries.each_with_object({}) { |e, h| h[e.key] = e.value }
        else
          # Return specific value
          entries.find { |e| e.key == key }&.value
        end
      end

      # Convenience method to set metadata
      # @param key [String] The metadata key
      # @param value [String] The value to set
      def set_metadata(key, value)
        self.metadata_entries ||= []
        existing = metadata_entries.find { |e| e.key == key }
        if existing
          existing.value = value
        else
          metadata_entries << MetadataEntry.new(key: key, value: value)
        end
      end

      # Get all element attributes as a hash, or a specific attribute value by name
      # @overload attr
      #   @return [Hash] All attributes as key-value pairs
      # @overload attr(name)
      #   @param name [String] The attribute name
      #   @return [String, nil] The value or nil
      def attr(name = nil)
        attrs = element_attributes || []
        if name.nil?
          # Return all attributes as hash
          attrs.each_with_object({}) { |a, h| h[a.name] = a.value }
        else
          # Return specific value
          attrs.find { |a| a.name == name }&.value
        end
      end

      # Set attribute value
      # @param name [String] The attribute name
      # @param value [String] The value to set
      def set_attr(name, value)
        self.element_attributes ||= []
        existing = element_attributes.find { |a| a.name == name }
        if existing
          existing.value = value
        else
          element_attributes << ElementAttribute.new(name: name, value: value)
        end
      end

      # Compare this model with another for semantic equivalence
      #
      # Semantic equivalence means the models represent the same semantic
      # content, even if their exact structure differs. This is different
      # from equality, which requires exact matching.
      #
      # @param other [Object] the object to compare with
      # @return [Boolean] true if semantically equivalent, false otherwise
      def semantically_equivalent?(other)
        return false unless other.is_a?(self.class)

        comparable_attributes.all? do |attr|
          compare_attribute(attr, other)
        end
      end

      # Accept a visitor to traverse this element
      #
      # Implements the visitor pattern for document traversal.
      # The visitor's visit method will be called with this element.
      #
      # @param visitor [Coradoc::Visitor::Base] Visitor to accept
      # @return [void]
      def accept(visitor)
        visitor.visit(self)
      end

      private

      # List of attributes to compare for semantic equivalence
      #
      # Override in subclasses to define which attributes matter for
      # equivalence. By default, only id and title are compared.
      #
      # @return [Array<Symbol>] list of attribute names to compare
      def comparable_attributes
        %i[id title]
      end

      # Compare a single attribute between this model and another
      def compare_attribute(attr, other)
        self_value = send(attr)
        other_value = other.send(attr)

        case self_value
        when Array
          compare_arrays(self_value, other_value)
        when Base
          self_value.semantically_equivalent?(other_value)
        else
          self_value == other_value
        end
      end

      # Compare two arrays for semantic equivalence
      def compare_arrays(arr1, arr2)
        return false unless arr1.size == arr2.size

        arr1.zip(arr2).all? do |item1, item2|
          if item1.is_a?(Base)
            item1.semantically_equivalent?(item2)
          else
            item1 == item2
          end
        end
      end
    end
  end
end
