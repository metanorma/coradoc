module Coradoc::Input::HTML
  module Converters
    class Blockquote < Base
      def to_coradoc(node, state = {})
        node["id"]
        cite = node["cite"]
        attributes = Coradoc::Element::AttributeList.new
        attributes.add_positional("quote", cite) if !cite.nil?
        content = treat_children(node, state).strip
        content = Coradoc::Input::HTML.cleaner.remove_newlines(content)
        Coradoc::Element::Block::Quote.new(nil, lines: content,
                                                attributes: attributes)
      end
    end

    register :blockquote, Blockquote.new
  end
end
