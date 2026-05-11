# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Open < Base
        def self.to_html(block, _options = {})
          return '' unless block

          content = process_content(block.content)

          attrs = { class: 'openblock' }
          attrs[:id] = block.id if block.id

          NodeBuilder.build(:div, content, **attrs).to_html
        end

        def self.to_coradoc(element, _options = {})
          return nil unless element.name == 'div'

          content = element.children.map do |node|
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

          Coradoc::CoreModel::OpenBlock.new(
            content: content,
            id: element['id']
          )
        end

        def self.process_content(content)
          return '' if content.nil?

          if content.is_a?(Array)
            content.map { |item| convert_item(item) }.join("\n")
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
      end
    end
  end
end
