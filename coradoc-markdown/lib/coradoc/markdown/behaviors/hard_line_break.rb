# frozen_string_literal: true

module Coradoc
  module Markdown
    module Behaviors
      # Hand-written behavior for HardLineBreak: tolerates (and ignores)
      # any keyword arguments so callers need not special-case it.
      module HardLineBreak
        def initialize(**_rest)
          super
        end
      end
    end
  end
end
