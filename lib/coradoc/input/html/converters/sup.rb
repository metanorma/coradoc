module Coradoc::ReverseAdoc
  module Converters
    class Sup < Base
      def to_coradoc(node, state = {})
        leading_whitespace, trailing_whitespace = extract_leading_trailing_whitespace(node)

        content = treat_children_coradoc(node, state)

        return content if Coradoc::Generator.gen_adoc(content).strip.empty?

        e = Coradoc::Element::Inline::Superscript.new(content)
        [leading_whitespace, e, trailing_whitespace]
      end
    end

    register :sup, Sup.new
  end
end
