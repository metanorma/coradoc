# frozen_string_literal: true

module Coradoc
  module Transform
    # Convenience module for transforming AsciiDoc models to CoreModel
    #
    # This module provides a stable API path for the AsciiDoc → CoreModel
    # transformation. It delegates to the actual transformer implementation
    # in the coradoc-adoc gem.
    #
    # @example Transforming an AsciiDoc document to CoreModel
    #   adoc_model = Coradoc::AsciiDoc.parse(adoc_text)
    #   core_model = Coradoc::Transform::AsciiDocToCoreModel.transform(adoc_model)
    #
    # @example Using the shorter alias
    #   core_model = Coradoc.to_core(adoc_model)
    #
    module AsciiDocToCoreModel
      class << self
        # Transform an AsciiDoc model to CoreModel
        #
        # @param model [Coradoc::AsciiDoc::Base] The AsciiDoc model to transform
        # @return [Coradoc::CoreModel::Base] The CoreModel equivalent
        # @raise [ArgumentError] If coradoc-adoc gem is not loaded
        def transform(model)
          unless defined?(Coradoc::AsciiDoc::Transform::ToCoreModel)
            raise ArgumentError,
                  'coradoc-adoc gem is required for AsciiDoc transformations. ' \
                  "Add 'require \"coradoc/asciidoc\"' to your code."
          end

          Coradoc::AsciiDoc::Transform::ToCoreModel.transform(model)
        end

        # Check if the AsciiDoc transformer is available
        #
        # @return [Boolean] True if coradoc-adoc is loaded
        def available?
          !!defined?(Coradoc::AsciiDoc::Transform::ToCoreModel)
        end
      end
    end
  end
end
