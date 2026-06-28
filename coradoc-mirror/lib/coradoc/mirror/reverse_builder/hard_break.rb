# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class HardBreak < Base
        def build(_node)
          CoreModel::HardLineBreakElement.new(content: '')
        end
      end
    end
  end
end
