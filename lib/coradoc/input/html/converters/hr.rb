module Coradoc
  module Input
    module Html
      module Converters
        class Hr < Base
          def to_coradoc(_node, _state = {})
            Coradoc::Element::Break::ThematicBreak.new
          end
        end

        register :hr, Hr.new
      end
    end
  end
end
