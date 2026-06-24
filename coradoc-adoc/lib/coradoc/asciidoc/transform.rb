# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      autoload :TransformerRegistry, "#{__dir__}/transform/transformer_registry"
      autoload :Registry, "#{__dir__}/transform/transformer_registry"
      autoload :ToCoreModel, "#{__dir__}/transform/to_core_model"
      autoload :ToCoreModelRegistrations, "#{__dir__}/transform/to_core_model_registrations"
      autoload :FromCoreModel, "#{__dir__}/transform/from_core_model"
      autoload :FromCoreModelRegistrations, "#{__dir__}/transform/from_core_model_registrations"
      autoload :TextExtractVisitor, "#{__dir__}/transform/text_extract_visitor"
      autoload :InlineTransformVisitor, "#{__dir__}/transform/inline_transform_visitor"
      autoload :ElementTransformers, "#{__dir__}/transform/element_transformers"
      autoload :FrontmatterAttributeMap, "#{__dir__}/transform/frontmatter_attribute_map"
      autoload :CalloutMerger, "#{__dir__}/transform/callout_merger"
      autoload :AttributeListToMetadata, "#{__dir__}/transform/attribute_list_to_metadata"
    end
  end
end
