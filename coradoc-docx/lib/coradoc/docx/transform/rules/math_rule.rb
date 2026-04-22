# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      module Rules
        # Transforms OMML math elements to CoreModel.
        #
        # Display math (m:oMathPara) → CoreModel::Block (stem)
        # Inline math (m:oMath) → CoreModel::InlineElement (stem)
        #
        # Uses Plurimath for OMML → LaTeX conversion when available.
        # Falls back to raw XML string when Plurimath is not loaded.
        class MathRule < Rule
          def matches?(element)
            return false unless defined?(Uniword::Math)

            element.is_a?(Uniword::Math::OMathPara) ||
              element.is_a?(Uniword::Math::OMath)
          end

          def apply(element, _context)
            latex = omml_to_latex(element)

            if display_math?(element)
              CoreModel::Block.new(
                element_type: 'block',
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

          private

          def display_math?(element)
            defined?(Uniword::Math::OMathPara) &&
              element.is_a?(Uniword::Math::OMathPara)
          end

          def omml_to_latex(element)
            if defined?(Plurimath)
              plurimath_to_latex(element)
            else
              # Fallback: serialize to XML string
              element_respond_to_xml(element) || ''
            end
          end

          def plurimath_to_latex(element)
            xml = element_to_xml(element)
            return '' if xml.nil? || xml.empty?

            begin
              formula = Plurimath::OMML.parse(xml)
              formula.to_latex
            rescue StandardError
              ''
            end
          end

          def element_to_xml(element)
            return '' unless element.respond_to?(:to_xml)

            element.to_xml
          end

          def element_respond_to_xml(element)
            element_to_xml(element)
          end
        end
      end
    end
  end
end
