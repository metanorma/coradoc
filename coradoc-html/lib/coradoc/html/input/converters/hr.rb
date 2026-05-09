# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Hr < Base
          def to_coradoc(_node, _state = {})
            Coradoc::CoreModel::Block.new(
              element_type: 'thematic_break',
              block_semantic_type: :horizontal_rule
            )
          end
        end

        register :hr, Hr.new
      end
    end
  end
end
