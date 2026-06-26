# frozen_string_literal: true

module Coradoc
  module CoreModel
    # STEM block — mathematical/scientific content authored in LaTeX,
    # AsciiMath, or another STEM markup. Carries a +language+ attribute so
    # downstream renderers know which interpreter to invoke.
    #
    # AsciiDoc surface forms:
    #   [stem]\n++++\nx^2\n++++        # language: "latex" (default)
    #   [latexmath]\n++++\nx^2\n++++   # language: "latex"
    #   [asciimath]\n++++\nx^2\n++++   # language: "asciimath"
    class StemBlock < Block
      attribute :language, :string, default: -> { 'latex' }

      def self.semantic_type
        :stem
      end
    end
  end
end
