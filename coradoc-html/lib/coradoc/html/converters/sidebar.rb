# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Sidebar < Base
        def self.to_html(sidebar, _options = {})
          return '' unless sidebar

          attrs = { class: 'sidebar' }
          attrs[:id] = sidebar.id if sidebar.id

          children = []

          children << NodeBuilder.build(:div, escape_html(sidebar.title.to_s), class: 'sidebar-title') if sidebar.title && !sidebar.title.to_s.empty?

          content = process_content(sidebar.content)
          children << content unless content.empty?

          NodeBuilder.build(:aside, children, **attrs).to_html
        end

        def self.to_coradoc(element, _options = {})
          return nil unless element.name == 'aside'

          title_elem = element.at_css('.sidebar-title, h1, h2, h3, h4, h5, h6')
          title = title_elem&.text&.strip

          content_nodes = if title_elem
                            element.children.reject { |node| node == title_elem }
                          else
                            element.children
                          end

          content = extract_content(content_nodes)

          Coradoc::CoreModel::SidebarBlock.new(
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
