# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Base
          # Default implementation to convert a given Nokogiri node
          # to a CoreModel type.
          # Can be overriden by subclasses.
          def convert(node, state = {})
            to_coradoc(node, state)
          end

          # NOTE: treat_children won't run plugin hooks
          def treat_children(node, state)
            node.children.map do |child|
              treat(child, state)
            end
          end

          def treat(node, state)
            Converters.process(node, state)
          end

          def treat_children_coradoc(node, state)
            results = node.children.map do |child|
              treat_coradoc(child, state)
            end.flatten

            results.reject do |x|
              x.nil? || (x.is_a?(String) && x.strip.empty?)
            end
          end

          def treat_coradoc(node, state)
            Converters.process_coradoc(node, state)
          end

          def extract_title(node)
            node['title'].to_s
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

            node2 = node.at_xpath('preceding-sibling::node()[1]')
            node2.is_a?(Nokogiri::XML::Text) && node2.text.match?(str)
          end

          def textnode_after_start_with?(node, str)
            return nil unless [String, Regexp].include?(str.class)
            return nil if str.is_a?(String) && str.empty?

            str = /#{Regexp.escape(str)}/ if str.is_a?(String)
            str = /\A(?:#{str})/

            node2 = node.at_xpath('following-sibling::node()[1]')
            node2.is_a?(Nokogiri::XML::Text) && node2.text.match?(str)
          end

          def extract_leading_trailing_whitespace(node)
            node.text =~ /^(\s+)/
            leading_whitespace = ::Regexp.last_match(1)
            unless leading_whitespace.nil?
              first_text = node.at_xpath('./text()[1]')
              first_text&.replace(first_text.text.lstrip)
              leading_whitespace = ' '
            end
            node.text =~ /(\s+)$/
            trailing_whitespace = ::Regexp.last_match(1)
            unless trailing_whitespace.nil?
              last_text = node.at_xpath('./text()[last()]')
              last_text&.replace(last_text.text.rstrip)
              trailing_whitespace = ' '
            end
            [leading_whitespace, trailing_whitespace]
          end

          def unconstrained_before?(node)
            before = node.at_xpath('preceding::node()[1]')

            before &&
              !before.text.strip.empty? &&
              before.text[-1]&.match?(/\w/)
          end

          def unconstrained_after?(node)
            after = node.at_xpath('following::node()[1]')

            after && !after.text.strip.empty? &&
              after.text[0]&.match?(/\w|,|;|"|\.\?!/)
          end

          # Helper to escape text content
          def escape_text(text)
            text.to_s.gsub(/[<>&]/, '<' => '&lt;', '>' => '&gt;', '&' => '&amp;')
          end
        end
      end
    end
  end
end
