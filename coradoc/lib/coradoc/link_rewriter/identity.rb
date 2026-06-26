# frozen_string_literal: true

module Coradoc
  module LinkRewriter
    # Default no-op rewriter. Returns every target unchanged. Used when
    # the caller only wants the visitor's immutable-copy guarantee.
    class Identity
      def call(target:, **)
        target
      end
    end
  end
end
