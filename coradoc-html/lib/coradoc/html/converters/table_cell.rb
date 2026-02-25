# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class TableCell < Base
        # Convert CoreModel::TableCell to HTML <td> or <th>
        #
        # @param cell [Coradoc::CoreModel::TableCell] Table cell model
        # @param _options [Hash] Conversion options
        # @return [String] HTML string
        def self.to_html(cell, _options = {})
          return '' unless cell

          # Check if this is a header cell
          is_header = cell.respond_to?(:header) && cell.header == true
          tag = is_header ? 'th' : 'td'

          # Build cell attributes
          attrs = build_attributes(cell)

          # Process cell content
          content = process_content(cell)

          # Wrap content in style tags if needed
          content = wrap_with_style(content, cell)

          "<#{tag}#{attrs}>#{content}</#{tag}>"
        end

        # Convert HTML <td> or <th> to CoreModel::TableCell
        def self.to_coradoc(element, _options = {})
          return nil unless %w[td th].include?(element.name)

          # Determine if this is a header cell
          is_header = element.name == 'th'

          # Extract content - could be text or nested elements
          content = extract_content(element)

          # Extract cell attributes
          attrs = extract_cell_attributes(element)

          Coradoc::CoreModel::TableCell.new(
            content: content,
            header: is_header,
            **attrs.compact
          )
        end

        # Build HTML attributes from CoreModel::TableCell
        def self.build_attributes(cell)
          attrs = []

          # Add ID if present
          attrs << %( id="#{escape_attribute(cell.id)}") if cell.respond_to?(:id) && cell.id

          # Colspan and rowspan
          attrs << %( colspan="#{cell.colspan}") if cell.respond_to?(:colspan) && cell.colspan
          attrs << %( rowspan="#{cell.rowspan}") if cell.respond_to?(:rowspan) && cell.rowspan

          # Build style attribute for alignment, colors, etc.
          style_parts = []

          # Horizontal alignment
          if cell.respond_to?(:alignment) && cell.alignment
            style_parts << "text-align: #{escape_attribute(cell.alignment)}"
          end

          # Vertical alignment
          if cell.respond_to?(:vertical_alignment) && cell.vertical_alignment
            style_parts << "vertical-align: #{escape_attribute(cell.vertical_alignment)}"
          end

          # Background color
          if cell.respond_to?(:bgcolor) && cell.bgcolor
            style_parts << "background-color: #{escape_attribute(cell.bgcolor)}"
          end

          # Text color
          style_parts << "color: #{escape_attribute(cell.color)}" if cell.respond_to?(:color) && cell.color

          # Width
          style_parts << "width: #{escape_attribute(cell.width)}" if cell.respond_to?(:width) && cell.width

          # Height
          style_parts << "height: #{escape_attribute(cell.height)}" if cell.respond_to?(:height) && cell.height

          # Add style attribute if we have any styles
          attrs << %( style="#{style_parts.join('; ')}") if style_parts.any?

          attrs.join
        end

        # Wrap content with style tags based on cell style
        def self.wrap_with_style(content, cell)
          return content unless cell.respond_to?(:style) && cell.style

          case cell.style.to_s.downcase
          when 'strong', 's'
            "<strong>#{content}</strong>"
          when 'emphasis', 'e'
            "<em>#{content}</em>"
          when 'monospace', 'm'
            "<code>#{content}</code>"
          when 'literal', 'l'
            # Literal content - preserve whitespace
            "<pre>#{content}</pre>"
          when 'verse', 'v'
            # Verse content - preserve formatting
            "<div class=\"verse\">#{content}</div>"
          else
            content
          end
        end

        def self.process_content(cell)
          return '' if cell.nil?

          # Use renderable_content if available (prefers children over content)
          content = if cell.respond_to?(:renderable_content)
                      cell.renderable_content
                    elsif cell.respond_to?(:children) && cell.children.any?
                      cell.children
                    elsif cell.respond_to?(:content)
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
            # Use convert_content_to_html for CoreModel types
            convert_content_to_html(item, {})
          end
        end

        def self.extract_content(element)
          # Extract content from the cell
          children = element.children

          if children.size == 1 && children.first.text?
            # Simple text content
            children.first.text
          else
            # Complex content with nested elements
            children.map do |child|
              if child.text?
                child.text
              else
                # Convert HTML element to CoreModel
                convert_node_to_core(child, {})
              end
            end.compact
          end
        end

        def self.extract_cell_attributes(element)
          attrs = {}

          # Extract colspan
          attrs[:colspan] = element['colspan'].to_i if element['colspan']

          # Extract rowspan
          attrs[:rowspan] = element['rowspan'].to_i if element['rowspan']

          # Extract styles from style attribute
          if element['style']
            style = element['style']

            # Horizontal alignment
            if style.include?('text-align')
              align = style[/text-align:\s*(\w+)/, 1]
              attrs[:alignment] = align if align
            end

            # Vertical alignment
            if style.include?('vertical-align')
              valign = style[/vertical-align:\s*(\w+)/, 1]
              attrs[:vertical_alignment] = valign if valign
            end

            # Background color
            if style.include?('background-color')
              bgcolor = style[/background-color:\s*([^;]+)/, 1]
              attrs[:bgcolor] = bgcolor.strip if bgcolor
            end

            # Text color
            if style.include?('color:')
              color = style[/color:\s*([^;]+)/, 1]
              attrs[:color] = color.strip if color
            end

            # Width
            if style.include?('width:')
              width = style[/width:\s*([^;]+)/, 1]
              attrs[:width] = width.strip if width
            end

            # Height
            if style.include?('height:')
              height = style[/height:\s*([^;]+)/, 1]
              attrs[:height] = height.strip if height
            end
          end

          attrs
        end
      end
    end
  end
end
