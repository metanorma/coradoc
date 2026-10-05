# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      module Rules
        # Transforms OMML math elements to CoreModel.
        #
        # Display math (MathEquation#block?) → CoreModel::Block (stem)
        # Inline math (MathEquation#inline?) → CoreModel::InlineElement (stem)
        #
        # LaTeX conversion is provided natively by Uniword::MathEquation.
        class MathRule < Rule
          def matches?(element)
            defined?(Uniword::MathEquation) &&
              element.is_a?(Uniword::MathEquation)
          end

          def apply(element, _context)
            latex = element.to_latex.to_s

            if element.block?
              CoreModel::PassBlock.new(
                delimiter_type: '++++',
                language: 'latexmath',
                content: latex
              )
            else
              CoreModel::InlineElement.new(
                format_type: 'stem',
                content: latex
              )
            end
          end
        end
      end
    end
  end
end
