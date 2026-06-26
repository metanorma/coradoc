# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Mirror
    module ReverseBuilder
      class TableBody < Base
        registers 'table_body'

        def build(node)
          build_content(node).first || CoreModel::TableRow.new
        end
      end
    end
  end
end
