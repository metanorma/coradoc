# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Skip < Base
          INSTANCE = new

          def to_coradoc(_node, _state = {})
            ''
          end

          def convert(_node, _state = {})
            ''
          end
        end

        register :caption, Skip::INSTANCE
        register :figcaption, Skip::INSTANCE
        register :title,     Skip::INSTANCE
        register :link,      Skip::INSTANCE
        register :style,     Skip::INSTANCE
        register :meta,      Skip::INSTANCE
        register :script,    Skip::INSTANCE
        register :comment,   Skip::INSTANCE
        register :colgroup,  Skip::INSTANCE
        register :col,       Skip::INSTANCE
      end
    end
  end
end
