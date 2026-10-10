# frozen_string_literal: true

require 'parsanol'

module Coradoc
  module AsciiDoc
    module Parser
      # Converts a native-engine parse tree: every
      # Parsanol::Slice becomes an immutable PositionedString. Runs at
      # the GrammarBackend boundary so the transformer and document
      # models never see pooled slices, without losing source
      # positions.
      module TreeMaterializer
        module_function

        def convert(node)
          case node
          when Parsanol::Slice then PositionedString.from_slice(node)
          when Hash then node.transform_values { |value| convert(value) }
          when Array then node.map { |value| convert(value) }
          else
            node
          end
        end
      end
    end
  end
end
