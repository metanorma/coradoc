module Coradoc
  module Input
    module Html
      module Converters
        class Text < Base
          def to_coradoc(node, state = {})
            return treat_empty(node, state) if node.text.strip.empty?

            Coradoc::Element::TextElement.new(node.text, html_cleanup: true)
          end

          private

          def treat_empty(node, state)
            parent = node.parent.name.to_sym
            if %i[ol ul].include?(parent) # Otherwise the identation is broken
              ""
            elsif state[:tdsinglepara]
              ""
            elsif node.text == " " # Regular whitespace text node
              " "
            else
              ""
            end
          end
        end

        register :text, Text.new
      end
    end
  end
end
