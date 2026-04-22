# frozen_string_literal: true

module Coradoc
  module Transform
    # Base class for all transformers
    #
    # Transformers convert between format-specific models and the CoreModel.
    # Each format gem should implement two transformers:
    # - ToCoreModel: Format Model -> CoreModel
    # - FromCoreModel: CoreModel -> Format Model
    #
    # This class includes the Helpers module for common transformation utilities.
    #
    # @example Implementing a custom transformer
    #   class MyFormat::Transform::ToCoreModel < Coradoc::Transform::Base
    #     def transform(document)
    #       # Convert MyFormat::Document to CoreModel structures
    #       CoreModel::StructuralElement.new(
    #         element_type: "document",
    #         title: document.title,
    #         children: transform_sections(document.sections)
    #       )
    #     end
    #
    #     private
    #
    #     def transform_sections(sections)
    #       sections.map { |s| transform_section(s) }
    #     end
    #   end
    class Base
      include Helpers
      # Transform a document from one model to another
      #
      # @param document [Object] the document to transform
      # @return [Object] the transformed document
      # @raise [NotImplementedError] if not implemented by subclass
      def transform(document)
        raise NotImplementedError,
              'Subclasses must implement #transform'
      end

      # Transform an array of elements
      #
      # @param elements [Array] the elements to transform
      # @return [Array] the transformed elements
      def transform_collection(elements)
        return [] if elements.nil?

        elements.map { |element| transform(element) }
      end

      # Check if the given object is a CoreModel type
      #
      # @param object [Object] the object to check
      # @return [Boolean] true if it's a CoreModel type
      def core_model?(object)
        object.is_a?(CoreModel::Base)
      end

      # Get the element type from a CoreModel object
      #
      # @param element [CoreModel::Base] the element
      # @return [String, nil] the element type
      def element_type(element)
        return element.element_type if element.respond_to?(:element_type) && element.element_type
        return class_to_element_type(element.class) if element.is_a?(CoreModel::Base)

        nil
      end

      private

      # Convert class name to element type string
      # @param klass [Class] the class
      # @return [String] the element type
      def class_to_element_type(klass)
        # Get the class name without module prefix and convert to snake_case
        class_name = klass.name.split('::').last
        # Simple camelCase to snake_case conversion
        class_name.gsub(/([A-Z])/) { |m| "_#{m.downcase}" }.sub(/^_/, '')
      end
    end
  end
end
