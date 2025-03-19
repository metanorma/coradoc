module Coradoc::Input::Html
  module Converters
    class Aside < Base
      def to_coradoc(node, state = {})
        content = treat_children(node, state)
        Coradoc::Element::Block::Side.new(lines: content.lines)
      end
    end

    register :aside, Aside.new
  end
end
