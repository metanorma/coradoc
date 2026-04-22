# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for CoreModel::Block (open) to HTML
      class Open < Base
        def self.to_html(block, _options = {})
          return '' unless block

          # Build content
          content = process_content(block.content)

          # Build attributes
          attrs = build_attributes(block)

          # Wrap in div with openblock class
          "<div#{attrs}>\n#{content}\n</div>"
        end

        # Convert HTML div to CoreModel::Block (open)
        def self.to_coradoc(element, _options = {})
          return nil unless element.name == 'div'

          # Extract content
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

          # Extract ID if present
          id = element['id']

          Coradoc::CoreModel::Block.new(
            delimiter_type: '--',
            content: content,
            id: id
          )
        end

        def self.build_attributes(block)
          attrs = []
          attrs << %( class="openblock")

          attrs << %( id="#{escape_attribute(block.id)}") if block.id

          attrs.join
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
            "<p>#{escape_html(item)}</p>"
          else
            convert_content_to_html(item)
          end
        end
      end
    end
  end
end
