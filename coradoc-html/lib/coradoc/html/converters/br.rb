# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Br < Base
        INSTANCE = new

        def to_coradoc(_node, _state = {})
          Coradoc::CoreModel::LineBreakElement.new
        end
      end

      register :br, Br::INSTANCE
    end
  end
end
