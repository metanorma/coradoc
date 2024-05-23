module Coradoc::ReverseAdoc
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

      def unconstrained_before?(node)
        before = node.at_xpath("preceding::node()[1]")

        before &&
          !before.text.strip.empty? &&
          before.text[-1]&.match?(/\w/)
      end

      def unconstrained_after?(node)
        after = node.at_xpath("following::node()[1]")

        after && !after.text.strip.empty? &&
          after.text[0]&.match?(/\w|,|;|"|\.\?!/)
      end

      def convert(node, state = {})
        Coradoc::Generator.gen_adoc(to_coradoc(node, state))
      end
    end
  end
end
