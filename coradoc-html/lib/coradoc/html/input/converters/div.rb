# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Div < Base
          INSTANCE = new

          def to_coradoc(node, state = {})
            id = node['id']
            contents = treat_children_coradoc(node, state)

            Coradoc::CoreModel::OpenBlock.new(
              children: contents,
              id: id
            )
          end
        end

        register :div, Div::INSTANCE
      end
    end
  end
end
