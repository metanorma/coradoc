module Coradoc
  module Input
    module Html
      module Converters
        class P < Base
          def to_coradoc(node, state = {})
            id = node["id"]
            content = treat_children_coradoc(node, state)

            Coradoc::Element::Paragraph.new(
              content:,
              id:,
              tdsinglepara: state[:tdsinglepara],
            )
          end
        end

        register :p, P.new
      end
    end
  end
end
