# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class SoftBreak < Base
        def build(_node)
          CoreModel::LineBreakElement.new
        end
      end
    end
  end
end
