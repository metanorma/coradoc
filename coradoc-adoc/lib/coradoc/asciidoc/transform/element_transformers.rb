# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      module ElementTransformers
        autoload :DocumentTransformer, "#{__dir__}/element_transformers/document_transformer"
        autoload :BlockTransformer, "#{__dir__}/element_transformers/block_transformer"
        autoload :ListTransformer, "#{__dir__}/element_transformers/list_transformer"
        autoload :InlineTransformer, "#{__dir__}/element_transformers/inline_transformer"
        autoload :TableTransformer, "#{__dir__}/element_transformers/table_transformer"
        autoload :OtherTransformer, "#{__dir__}/element_transformers/other_transformer"
        autoload :IncludeTransformer, "#{__dir__}/element_transformers/include_transformer"
        autoload :AdmonitionStyles, "#{__dir__}/element_transformers/admonition_styles"
      end
    end
  end
end
