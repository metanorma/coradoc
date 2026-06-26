# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      class SoftBreak < Base
        registers 'soft_break'

        def build(_node)
          CoreModel::LineBreakElement.new
        end
      end
    end
  end
end
