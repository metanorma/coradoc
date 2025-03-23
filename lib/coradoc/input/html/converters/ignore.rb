module Coradoc
  module Input
    module Html
      module Converters
        class Ignore < Base
          def to_coradoc(node, state = {})
            convert(node, state)
          end

          def convert(_node, _state = {})
            "" # noop
          end
        end

        register :colgroup, Ignore.new
        register :col,      Ignore.new
      end
    end
  end
end
