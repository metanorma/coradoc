# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Hr < Base
          def to_coradoc(_node, _state = {})
            Coradoc::CoreModel::Block.new(
              element_type: 'thematic_break',
              delimiter_type: "'''"
            )
          end
        end

        register :hr, Hr.new
      end
    end
  end
end
