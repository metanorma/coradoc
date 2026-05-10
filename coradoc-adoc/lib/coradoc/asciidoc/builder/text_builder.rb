# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    class Builder
      module TextBuilder
        def build_nested_inlines(ast)
          nested = []

          ast.each_value do |value|
            next unless value.is_a?(Array)

            value.each do |item|
              nested << build_inline(item) if item.is_a?(Hash) && has_inline_structure?(item)
            end
          end

          nested
        end
      end
    end
  end
end
