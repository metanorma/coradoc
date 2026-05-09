# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Hr < Base
          def to_coradoc(_node, _state = {})
            Coradoc::CoreModel::HorizontalRuleBlock.new
          end
        end

        register :hr, Hr.new
      end
    end
  end
end
