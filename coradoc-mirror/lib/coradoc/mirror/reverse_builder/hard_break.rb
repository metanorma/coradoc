# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      class HardBreak < Base
        registers 'hard_break'

        def build(_node)
          CoreModel::HardLineBreakElement.new(content: '')
        end
      end
    end
  end
end
