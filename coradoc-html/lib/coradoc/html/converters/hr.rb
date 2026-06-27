# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Hr < Base
        INSTANCE = new

        def to_coradoc(_node, _state = {})
          Coradoc::CoreModel::HorizontalRuleBlock.new
        end
      end

      register :hr, Hr::INSTANCE
    end
  end
end
