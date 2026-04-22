# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for CoreModel::Block (example) to HTML <div class="example">
      class Example < Base
        # Convert CoreModel::Block (example) to HTML <div class="example">
        def self.to_html(example, _options = {})
          return '' unless example

          # Build div attributes
          attrs = build_attributes(example)

          # Build title if present
          title_html = build_title(example)

          # Process example content
          content = process_content(example.content)

          # Combine title and content
          example_html = ''
          example_html += "#{title_html}\n" if title_html
          example_html += content

          %(<div#{attrs}>\n#{example_html}\n</div>)
        end

        # Convert HTML <div class="example"> to CoreModel::Block (example)
        def self.to_coradoc(element, _options = {})
          return nil unless element.name == 'div'
          return nil unless element['class']&.include?('example')

          # Extract title if present
          title_elem = element.at_css('.example-title')
          title = title_elem&.text&.strip

          # Extract content - all children except title
          content_nodes = if title_elem
                            element.children.reject { |node| node == title_elem }
                          else
                            element.children
                          end

          content = extract_content(content_nodes)

          # Extract ID if present
          id = element['id']

          Coradoc::CoreModel::Block.new(
            delimiter_type: '====',
            content: content,
            title: title,
            id: id
          )
        end

        def self.build_attributes(example)
          attrs = [%( class="example")]

          # Add ID if present
          attrs << %( id="#{escape_attribute(example.id)}") if example.id

          attrs.join
        end

        def self.build_title(example)
          return nil unless example.title

          title_text = example.title.to_s
          return nil if title_text.empty?

          %(<div class="example-title">#{escape_html(title_text)}</div>)
        end

        def self.process_content(content)
          return '' if content.nil?

          if content.is_a?(Array)
            content.map { |item| convert_item(item) }.join("\n")
          elsif content.is_a?(String)
            "<p>#{escape_html(content)}</p>"
          else
            convert_item(content)
          end
        end

        def self.convert_item(item)
          case item
          when String
            "<p>#{escape_html(item)}</p>"
          else
            convert_content_to_html(item)
          end
        end

        def self.extract_content(nodes)
          # Extract and convert content nodes
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
