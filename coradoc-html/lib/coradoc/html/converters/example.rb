# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Example < Base
        def self.to_html(example, _options = {})
          return '' unless example

          attrs = { class: 'example' }
          attrs[:id] = example.id if example.id

          children = []

          children << NodeBuilder.build(:div, escape_html(example.title.to_s), class: 'example-title') if example.title && !example.title.to_s.empty?

          content = process_content(example.content)
          children << content unless content.empty?

          NodeBuilder.build(:div, children, **attrs).to_html
        end

        def self.to_coradoc(element, _options = {})
          return nil unless element.name == 'div'
          return nil unless element['class']&.include?('example')

          title_elem = element.at_css('.example-title')
          title = title_elem&.text&.strip

          content_nodes = if title_elem
                            element.children.reject { |node| node == title_elem }
                          else
                            element.children
                          end

          content = extract_content(content_nodes)

          Coradoc::CoreModel::ExampleBlock.new(
            content: content,
            title: title,
            id: element['id']
          )
        end

        def self.process_content(content)
          return '' if content.nil?

          if content.is_a?(Array)
            content.map { |item| convert_item(item) }.join("\n")
          elsif content.is_a?(String)
            NodeBuilder.build(:p, escape_html(content)).to_html
          else
            convert_item(content)
          end
        end

        def self.convert_item(item)
          case item
          when String
            NodeBuilder.build(:p, escape_html(item)).to_html
          else
            convert_content_to_html(item)
          end
        end

        def self.extract_content(nodes)
          nodes.map do |node|
            if node.text? && !node.text.strip.empty?
              node.text.strip
            elsif node.element?
              case node.name
              when 'p'
                Paragraph.to_coradoc(node)
              else
                node.text.strip
              end
            end
          end.compact
        end
      end
    end
  end
end
