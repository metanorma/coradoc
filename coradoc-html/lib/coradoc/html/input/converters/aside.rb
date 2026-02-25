# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Aside < Base
          def to_coradoc(node, state = {})
            content = treat_children_coradoc(node, state)
            # Use AnnotationBlock with annotation_type: "sidebar" for aside elements
            Coradoc::CoreModel::AnnotationBlock.new(
              annotation_type: 'sidebar',
              delimiter_type: '****',
              children: content
            )
          end
        end

        register :aside, Aside.new
      end
    end
  end
end
