module Coradoc::ReverseAdoc
  module Converters
    class Div < Base
      def to_coradoc(node, state = {})
        id = node["id"]
        contents = treat_children_coradoc(node, state)
        Coradoc::Element::Section.new(nil, id: id, contents: contents)
      end
    end

    register :div,     Div.new
    register :article, Div.new
  end
end
