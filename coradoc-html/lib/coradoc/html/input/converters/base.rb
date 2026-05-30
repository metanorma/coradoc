# frozen_string_literal: true

module Coradoc
  module Input
    module Html
      module Converters
        class Base
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
              node.ancestors(name).any?
            when Array
              name.any? { |n| node.ancestors(n).any? }
            end
          end

          def textnode_before_end_with?(node, str)
            return false unless [String, Regexp].include?(str.class)
            return false if str.is_a?(String) && str.empty?

            str = /#{Regexp.escape(str)}/ if str.is_a?(String)
            str = /(?:#{str})\z/

            node2 = node.at_xpath('preceding-sibling::node()[1]')
            node2.is_a?(Nokogiri::XML::Text) && node2.text.match?(str)
          end

          def textnode_after_start_with?(node, str)
            return false unless [String, Regexp].include?(str.class)
            return false if str.is_a?(String) && str.empty?

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

          # Extract plain text from a mixed content array.
          # Handles String, InlineElement (via .content), and other
          # CoreModel::Base (via .content or .title).
          def extract_text_from_content(content)
            return content if content.is_a?(String)
            return '' if content.nil?

            content.map do |item|
              case item
              when String
                item
              when Coradoc::CoreModel::InlineElement
                item.content.to_s
              when Coradoc::CoreModel::Base
                if item.content
                  item.content.to_s
                else
                  ''
                end
              else
                item.to_s
              end
            end.join
          end
        end
      end
    end
  end
end
