# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      class TableHead < Base
        registers 'table_head'

        def build(node)
          build_content(node).first || CoreModel::TableRow.new
        end
      end
    end
  end
end
