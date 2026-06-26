# frozen_string_literal: true

module Coradoc
  module Reference
    module Result
      # Multiple candidates matched. The catalog returned an Array.
      # Callers' +ambiguous:+ policy decides what to do.
      class Ambiguous < Base
        attribute :candidates, Coradoc::CoreModel::Base, collection: true

        def self.build(edge:, address:, candidates:)
          new(edge: edge, address: address, candidates: candidates)
        end
      end
    end
  end
end
