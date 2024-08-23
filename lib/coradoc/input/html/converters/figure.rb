module Coradoc::ReverseAdoc
  module Converters
    class Figure < Base
      def to_coradoc(node, state = {})
        id = node["id"]
        title = extract_title(node)
        content = treat_children_coradoc(node, state)
        Coradoc::Element::Block::Example.new(title, lines: content, id: id)
      end

      def extract_title(node)
        title = node.at("./figcaption")
        return "" if title.nil?

        treat_children_coradoc(title, {})
      end
    end

    register :figure, Figure.new
  end
end
