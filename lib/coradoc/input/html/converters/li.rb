module Coradoc::Input::HTML
  module Converters
    class Li < Base
      def to_coradoc(node, state = {})
        id = node["id"]
        content = treat_children_coradoc(node, state)
        Coradoc::Element::ListItem.new(content, id: id)
      end
    end

    register :li, Li.new
  end
end
