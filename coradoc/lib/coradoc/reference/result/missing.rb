# frozen_string_literal: true

module Coradoc
  module Reference
    module Result
      # No catalog knows this address. Caller's +missing:+ policy decides.
      class Missing < Base
        def self.build(edge:, address:)
          new(edge: edge, address: address)
        end
      end
    end
  end
end
