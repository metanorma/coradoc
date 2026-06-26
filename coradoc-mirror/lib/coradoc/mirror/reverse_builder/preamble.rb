# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      class Preamble < Base
        registers 'preface'

        def build(node)
          CoreModel::PreambleElement.new(children: build_content(node))
        end
      end
    end
  end
end
