# frozen_string_literal: true

module Coradoc
  module Mirror
    module ReverseBuilder
      class Toc < Base
        def build(_node)
          CoreModel::Toc.new
        end
      end
    end
  end
end
