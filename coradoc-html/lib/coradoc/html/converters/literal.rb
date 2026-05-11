# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Literal < Base
        def self.to_html(literal, _options = {})
          return '' unless literal

          attrs = { class: 'literal' }
          attrs[:id] = literal.id if literal.id

          content = process_content(literal.content)
          pre_node = NodeBuilder.build(:pre, content, **attrs)

          if literal.title && !literal.title.to_s.empty?
            title_node = NodeBuilder.build(:div, escape_html(literal.title.to_s), class: 'literal-title')
            NodeBuilder.build(:div, [title_node, pre_node], class: 'literal-block').to_html
          else
            pre_node.to_html
          end
        end

        def self.to_coradoc(element, _options = {})
          pre_elem = if element.name == 'div' && element['class']&.include?('literal-block')
                       element.at_css('pre')
                     elsif element.name == 'pre'
                       return nil if element['class']&.include?('code')

                       element
                     else
                       return nil
                     end

          return nil unless pre_elem

          title = if element.name == 'div'
                    title_elem = element.at_css('.literal-title')
                    title_elem&.text&.strip
                  end

          content = pre_elem.text
          id = pre_elem['id'] || element['id']

          Coradoc::CoreModel::LiteralBlock.new(
            content: content,
            title: title,
            id: id
          )
        end

        def self.process_content(content)
          return '' if content.nil?

          if content.is_a?(String)
            escape_html(content)
          elsif content.is_a?(Array)
            content.map { |line| escape_html(line.to_s) }.join("\n")
          else
            escape_html(content.to_s)
          end
        end
      end
    end
  end
end
