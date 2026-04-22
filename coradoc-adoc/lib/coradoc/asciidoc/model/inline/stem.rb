# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Inline
        # Stem inline element for AsciiDoc documents.
        #
        # STEM macros are mathematical notation: stem:[formula] or latexmath:[formula]
        #
        # @!attribute [r] type
        #   @return [String] The stem type (stem, latexmath, asciimath)
        #
        # @!attribute [r] content
        #   @return [String] The mathematical content/formula
        #
        class Stem < Base
          attribute :type, :string, default: 'stem'
          attribute :content, :string
        end
      end
    end
  end
end
