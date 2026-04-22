# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Div < Base
          def to_coradoc(node, state = {})
            id = node['id']
            contents = treat_children_coradoc(node, state)

            Coradoc::CoreModel::Block.new(
              delimiter_type: '--',
              content: contents,
              id: id
            )
          end
        end

        register :div,     Div.new
        register :article, Div.new
        register :center,  Div.new
      end
    end
  end
end
