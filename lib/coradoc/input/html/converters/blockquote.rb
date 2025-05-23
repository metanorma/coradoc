module Coradoc
  module Input
    module Html
      module Converters
        class Blockquote < Base
          def to_coradoc(node, state = {})
            node["id"]
            cite = node["cite"]
            attributes = Coradoc::Element::AttributeList.new
            attributes.add_positional("quote", cite) if !cite.nil?
            content = treat_children(node, state).strip
            content = Coradoc::Input::Html.cleaner.remove_newlines(content)
            Coradoc::Element::Block::Quote.new(
              title: nil,
              lines: content,
              attributes:,
            )
          end
        end

        register :blockquote, Blockquote.new
      end
    end
  end
end
