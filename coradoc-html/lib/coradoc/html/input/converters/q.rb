# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Q < Base
          INSTANCE = new

          def to_coradoc(node, state = {})
            content = treat_children_coradoc(node, state)
            cite = node['cite']

            Coradoc::CoreModel::InlineElement.new(
              format_type: 'quotation',
              nested_elements: content,
              content: extract_text_from_content(content),
              target: cite
            )
          end
        end

        register :q, Q::INSTANCE
      end
    end
  end
end
