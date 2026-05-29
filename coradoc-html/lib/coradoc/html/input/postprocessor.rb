# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      # Postprocessor hook for CoreModel tree transformations after HTML parsing.
      #
      # Override or extend to apply post-parse cleanup. The default
      # implementation returns the tree unchanged.
      class Postprocessor
        def self.process(coradoc)
          new(coradoc).process
        end

        def initialize(coradoc)
          @tree = coradoc
        end

        def process
          @tree
        end
      end
    end
  end
end
