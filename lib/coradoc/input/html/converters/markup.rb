module Coradoc::Input::Html
  module Converters
    class Markup < Base
      def to_coradoc(node, state = {})
        u_before = unconstrained_before?(node)
        u_after = unconstrained_after?(node)

        leading_whitespace, trailing_whitespace =
          extract_leading_trailing_whitespace(node)

        content = treat_children_coradoc(node, state)

        if node_has_ancestor?(node, markup_ancestor_tag_names)
          content
        elsif node.children.empty?
          leading_whitespace.to_s
        else
          u = (u_before && leading_whitespace.nil?) ||
            (u_after && trailing_whitespace.nil?)

          e = coradoc_class.new(content, unconstrained: u)
          [leading_whitespace, e, trailing_whitespace]
        end
      end
    end
  end
end
