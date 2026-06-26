# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      class HorizontalRule < Base
        registers 'horizontal_rule', 'thematic_break'

        def build(_node)
          CoreModel::HorizontalRuleBlock.new
        end
      end
    end
  end
end
