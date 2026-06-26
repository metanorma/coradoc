# frozen_string_literal: true

module Coradoc
  module Reference
    # Sum type for resolution outcomes. Callers pattern-match on the
    # concrete subclass — never check +nil+.
    #
    #   case resolver.resolve(edge)
    #   in Result::Resolved => r   # have the target
    #   in Result::Ambiguous => a  # multiple candidates
    #   in Result::Missing => m    # catalog does not know
    #   in Result::Deferred => d   # might know later
    #   end
    module Result
      autoload :Base, "#{__dir__}/result/base"
      autoload :Resolved, "#{__dir__}/result/resolved"
      autoload :Ambiguous, "#{__dir__}/result/ambiguous"
      autoload :Missing, "#{__dir__}/result/missing"
      autoload :Deferred, "#{__dir__}/result/deferred"
    end
  end
end
