# frozen_string_literal: true

module Coradoc
  module Reference
    module Materializer
      # Default fallback. Returns the original edge-bearing node
      # unchanged — an unresolvable or unrenderable reference survives
      # materialization exactly as authored, so round-tripping is
      # always safe and no content is ever lost.
      class Passthrough < Base
        class << self
          def kind
            :any
          end

          def presentation
            :any
          end

          def format
            :any
          end
        end

        def materialize(edge:, result:, node:, **)
          node
        end
      end
    end
  end
end
