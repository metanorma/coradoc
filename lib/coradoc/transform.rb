# frozen_string_literal: true

module Coradoc
  # Transform module for format-to-format transformations
  #
  # The Transform module provides the base infrastructure for transforming
  # documents between different format-specific models. Each format gem
  # implements ToCoreModel and FromCoreModel transformers.
  #
  # @example Transforming AsciiDoc to CoreModel
  #   transformer = Coradoc::AsciiDoc::Transform::ToCoreModel.new
  #   core_doc = transformer.transform(asciidoc_doc)
  #
  # @example Transforming CoreModel to HTML
  #   transformer = Coradoc::Html::Transform::FromCoreModel.new
  #   html_doc = transformer.transform(core_doc)
  module Transform
    autoload :Base, 'coradoc/transform/base'
    autoload :Helpers, 'coradoc/transform/helpers'
    autoload :ClassHelpers, 'coradoc/transform/helpers'
  end
end
