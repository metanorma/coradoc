# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      # Postprocessor's aim is to convert a Coradoc tree from
      # a mess that has been created from HTML into a tree that
      # is compatible with what we would get out of Coradoc, if
      # it parsed it directly.
      #
      # Now operates on CoreModel types exclusively.
      class Postprocessor
        def self.process(coradoc)
          new(coradoc).process
        end

        def initialize(coradoc)
          @tree = coradoc
        end

        # Main processing entry point
        def process
          # For now, just return the tree as-is since CoreModel
          # structure is already clean and well-formed.
          # Future: implement CoreModel-based postprocessing
          @tree
        end
      end
    end
  end
end
