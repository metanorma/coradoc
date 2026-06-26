# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      class Toc < Base
        registers 'toc'

        def build(_node)
          CoreModel::Toc.new
        end
      end
    end
  end
end
