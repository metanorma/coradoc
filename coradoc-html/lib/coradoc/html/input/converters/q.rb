# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Q < Base
          def to_coradoc(node, state = {})
            content = treat_children_coradoc(node, state)
            cite = node['cite']

            Coradoc::CoreModel::InlineElement.new(
              format_type: 'quotation',
              content: content,
              metadata: cite ? { cite: cite } : {}
            )
          end
        end

        register :q, Q.new
      end
    end
  end
end
