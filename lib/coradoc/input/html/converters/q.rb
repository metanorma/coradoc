module Coradoc::Input::HTML
  module Converters
    class Q < Base
      def to_coradoc(node, state = {})
        content = treat_children(node, state)
        Coradoc::Element::Inline::Quotation.new(content)
      end
    end

    register :q, Q.new
  end
end
