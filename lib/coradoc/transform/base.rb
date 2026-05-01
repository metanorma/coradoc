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
    end
  end
end
