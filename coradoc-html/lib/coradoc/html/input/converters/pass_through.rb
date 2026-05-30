# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class PassThrough < Base
          INSTANCE = new

          def to_coradoc(node, _state = {})
            node.to_s
          end
        end
      end
    end
  end
end
