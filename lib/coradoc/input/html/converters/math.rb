# Unless run with Coradoc::Input::HTML.config.mathml2asciimath,
# this is cheating: we're injecting MathML into Asciidoctor, but
# Asciidoctor only understands AsciiMath or LaTeX

require "plurimath"

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
            stem = node.to_s.tr("\n", " ")
            if Coradoc::Input::Html.config.mathml2asciimath
              stem = Plurimath::Math.parse(stem, :mathml).to_asciimath
            end

            unless stem.nil?
              stem = stem.gsub("[", "\\[").gsub("]", "\\]").gsub(
                /\(\(([^\)]+)\)\)/, "(\\1)"
              )
            end

            # TODO: This is to be done in Coradoc
            " stem:[" << stem << "] "
          end
        end

        register :math, Math.new
      end
    end
  end
end
