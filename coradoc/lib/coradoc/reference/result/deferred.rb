# frozen_string_literal: true

module Coradoc
  module Reference
    module Result
      # A catalog (typically Remote) might know this address later —
      # network is down, cache cold, etc. Caller may retry.
      class Deferred < Base
        attribute :reason, :string

        def self.build(edge:, address:, reason:)
          new(edge: edge, address: address, reason: reason)
        end
      end
    end
  end
end
