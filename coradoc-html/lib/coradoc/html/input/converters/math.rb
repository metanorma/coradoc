# frozen_string_literal: true

# Unless run with Coradoc::Input::HTML.config.mathml2asciimath,
# this is cheating: we're injecting MathML into Asciidoctor, but
# Asciidoctor only understands AsciiMath or LaTeX

module Coradoc
  module Input
    module Html
      module Converters
        class Math < Base
          # FIXIT
          def to_coradoc(node, state = {})
            convert(node, state)
          end

          def convert(node, _state = {})
            stem = node.to_s.tr("\n", ' ')
            if Coradoc::Html::Input.config.mathml2asciimath
              require 'plurimath'
              stem = Plurimath::Math.parse(stem, :mathml).to_asciimath
            end

            unless stem.nil?
              stem = stem.gsub('[', '\\[')
              stem = stem.gsub(']', '\\]')
              # Handle ((...)) patterns - iterate to avoid polynomial regex
              loop do
                new_stem = stem.gsub(/\(\(([^)]{1,100})\)\)/, '(\\1)')
                break if new_stem == stem

                stem = new_stem
              end
            end

            # NOTE: MathML/LaTeX conversion to AsciiDoc stem format
            # This converts HTML math elements to AsciiDoc's stem:[] macro format
            ' stem:[' << stem << '] '
          end
        end

        register :math, Math.new
      end
    end
  end
end
