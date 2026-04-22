# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Br < Base
          def to_coradoc(_node, _state = {})
            Coradoc::CoreModel::InlineElement.new(
              format_type: 'line_break'
            )
          end
        end

        register :br, Br.new
      end
    end
  end
end
