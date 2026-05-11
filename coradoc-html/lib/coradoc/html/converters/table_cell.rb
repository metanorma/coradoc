# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class TableCell < Base
        def self.to_html(cell, _options = {})
          return '' unless cell

          tag = cell.header == true ? :th : :td

          attrs = build_attrs(cell)
          content = process_content(cell)
          content = wrap_with_style(content, cell)

          NodeBuilder.build(tag, content, **attrs).to_html
        end

        def self.to_coradoc(element, _options = {})
          return nil unless %w[td th].include?(element.name)

          is_header = element.name == 'th'
          content = extract_content(element)
          attrs = extract_cell_attributes(element)

          Coradoc::CoreModel::TableCell.new(
            content: content,
            header: is_header,
            **attrs.compact
          )
        end

        def self.build_attrs(cell)
          attrs = {}
          attrs[:id] = cell.id if cell.id
          attrs[:colspan] = cell.colspan.to_s if cell.colspan
          attrs[:rowspan] = cell.rowspan.to_s if cell.rowspan

          style_parts = []
          style_parts << "text-align: #{cell.alignment}" if cell.alignment
          style_parts << "vertical-align: #{cell.vertical_alignment}" if cell.vertical_alignment
          attrs[:style] = style_parts.join('; ') if style_parts.any?

          attrs
        end

        def self.wrap_with_style(content, cell)
          return content unless cell.style

          case cell.style.to_s.downcase
          when 'strong', 's'
            NodeBuilder.build(:strong, content).to_html
          when 'emphasis', 'e'
            NodeBuilder.build(:em, content).to_html
          when 'monospace', 'm'
            NodeBuilder.build(:code, content).to_html
          when 'literal', 'l'
            NodeBuilder.build(:pre, content).to_html
          when 'verse', 'v'
            NodeBuilder.build(:div, content, class: 'verse').to_html
          else
            content
          end
        end

        def self.process_content(cell)
          return '' if cell.nil?

          content = if cell.renderable_content
                      cell.renderable_content
                    elsif cell.children.any?
                      cell.children
                    elsif cell.content
                      cell.content
                    else
                      cell
                    end

          if content.is_a?(Array)
            content.map { |item| convert_item(item) }.join
          else
            convert_item(content)
          end
        end

        def self.convert_item(item)
          case item
          when String
            escape_html(item)
          else
            convert_content_to_html(item, {})
          end
        end

        def self.extract_content(element)
          children = element.children

          if children.size == 1 && children.first.text?
            children.first.text
          else
            children.map do |child|
              if child.text?
                child.text
              else
                convert_node_to_core(child, {})
              end
            end.compact
          end
        end

        def self.extract_cell_attributes(element)
          attrs = {}

          attrs[:colspan] = element['colspan'].to_i if element['colspan']
          attrs[:rowspan] = element['rowspan'].to_i if element['rowspan']

          if element['style']
            style = element['style']

            align = style[/text-align:\s*(\w+)/, 1]
            attrs[:alignment] = align if align

            valign = style[/vertical-align:\s*(\w+)/, 1]
            attrs[:vertical_alignment] = valign if valign

            color = style[/color:\s*([^;]+)/, 1]
            attrs[:color] = color.strip if color

            width = style[/width:\s*([^;]+)/, 1]
            attrs[:width] = width.strip if width

            height = style[/height:\s*([^;]+)/, 1]
            attrs[:height] = height.strip if height
          end

          attrs
        end
      end
    end
  end
end
