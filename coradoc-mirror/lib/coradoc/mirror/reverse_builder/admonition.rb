# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class Admonition < Base
        def build(node)
          CoreModel::AnnotationBlock.new(
            annotation_type: node.attrs&.admonition_type,
            content: extract_text(node)
          )
        end
      end
    end
  end
end
