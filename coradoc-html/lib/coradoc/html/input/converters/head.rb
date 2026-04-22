# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Head < Base
          def to_coradoc(node, _state = {})
            title = extract_title(node)
            # Use StructuralElement with element_type "document" for document header
            Coradoc::CoreModel::StructuralElement.new(
              element_type: 'document',
              title: title,
              level: 0
            )
          end

          def extract_title(node)
            title = node.at('./title')
            return '(???)' if title.nil?

            title.text
          end
        end

        register :head, Head.new
      end
    end
  end
end
