# frozen_string_literal: true

module Coradoc
  module Html
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
