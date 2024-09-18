module Coradoc::Input::HTML
  module Converters
    class Base
      # Default implementation to convert a given Nokogiri node
      # to an AsciiDoc script.
      # Can be overriden by subclasses.
      def convert(node, state = {})
        Coradoc::Generator.gen_adoc(to_coradoc(node, state))
      end

      # Note: treat_children won't run plugin hooks
      def treat_children(node, state)
        node.children.map do |child|
          treat(child, state)
        end.join
      end

      def treat(node, state)
        Converters.process(node, state)
      end

      def treat_children_coradoc(node, state)
        node.children.map do |child|
          treat_coradoc(child, state)
        end.flatten.reject { |x| x.to_s.empty? }
      end

      def treat_coradoc(node, state)
        Converters.process_coradoc(node, state)
      end

      def extract_title(node)
        title = Coradoc::Element::TextElement.escape_keychars(
          node["title"].to_s,
        )
        title.empty? ? "" : %[ #{title}]
      end

      def node_has_ancestor?(node, name)
        case name
        when String
          node.ancestors.map(&:name).include?(name)
        when Array
          (node.ancestors.map(&:name) & name).any?
        end
      end

      def textnode_before_end_with?(node, str)
        return nil unless [String, Regexp].include?(str.class)
        return nil if str.is_a?(String) && str.empty?

        str = /#{Regexp.escape(str)}/ if str.is_a?(String)
        str = /(?:#{str})\z/

        node2 = node.at_xpath("preceding-sibling::node()[1]")
        node2.respond_to?(:text) && node2.text.match?(str)
      end

      def textnode_after_start_with?(node, str)
        return nil unless [String, Regexp].include?(str.class)
        return nil if str.is_a?(String) && str.empty?

        str = /#{Regexp.escape(str)}/ if str.is_a?(String)
        str = /\A(?:#{str})/

        node2 = node.at_xpath("following-sibling::node()[1]")
        node2.respond_to?(:text) && node2.text.match?(str)
      end

      def extract_leading_trailing_whitespace(node)
        node.text =~ /^(\s+)/
        leading_whitespace = $1
        if !leading_whitespace.nil?
          first_text = node.at_xpath("./text()[1]")
          first_text.replace(first_text.text.lstrip)
          leading_whitespace = " "
        end
        node.text =~ /(\s+)$/
        trailing_whitespace = $1
        if !trailing_whitespace.nil?
          last_text = node.at_xpath("./text()[last()]")
          last_text.replace(last_text.text.rstrip)
          trailing_whitespace = " "
        end
        [leading_whitespace, trailing_whitespace]
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
    end
  end
end
