# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for CoreModel::Block (sidebar) to HTML <aside>
      class Sidebar < Base
        # Convert CoreModel::Block (sidebar) to HTML <aside>
        def self.to_html(sidebar, _options = {})
          return '' unless sidebar

          # Build aside attributes
          attrs = build_attributes(sidebar)

          # Build title if present
          title_html = build_title(sidebar)

          # Process sidebar content
          content = process_content(sidebar.content)

          # Combine title and content
          sidebar_html = ''
          sidebar_html += "#{title_html}\n" if title_html
          sidebar_html += content

          %(<aside#{attrs}>\n#{sidebar_html}\n</aside>)
        end

        # Convert HTML <aside> to CoreModel::Block (sidebar)
        def self.to_coradoc(element, _options = {})
          return nil unless element.name == 'aside'

          # Extract title if present
          title_elem = element.at_css('.sidebar-title, h1, h2, h3, h4, h5, h6')
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
            delimiter_type: '****',
            content: content,
            title: title,
            id: id
          )
        end

        def self.build_attributes(sidebar)
          attrs = [%( class="sidebar")]

          # Add ID if present
          attrs << %( id="#{escape_attribute(sidebar.id)}") if sidebar.id

          attrs.join
        end

        def self.build_title(sidebar)
          return nil unless sidebar.title

          title_text = sidebar.title.to_s
          return nil if title_text.empty?

          %(<div class="sidebar-title">#{escape_html(title_text)}</div>)
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
