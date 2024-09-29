module Coradoc::Input::HTML
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
    register :center,  Div.new
  end
end
