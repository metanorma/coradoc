# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class HorizontalRule < Base
        def build(_node)
          CoreModel::HorizontalRuleBlock.new
        end
      end
    end
  end
end
