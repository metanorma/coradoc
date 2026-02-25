# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for CoreModel::AnnotationBlock to HTML admonition block
      class Admonition < Base
        # Convert CoreModel::AnnotationBlock to HTML admonition block
        def self.to_html(admonition, _options = {})
          return '' unless admonition

          # Get admonition type (NOTE, TIP, IMPORTANT, WARNING, CAUTION)
          type = admonition.annotation_type ? admonition.annotation_type.to_s.upcase : 'NOTE'

          # Build div attributes
          attrs = build_attributes(admonition, type)

          # Build title if present
          title_html = build_title(admonition)

          # Build admonition label
          label = build_label(type)

          # Process admonition content
          content = process_content(admonition.content)

          # Combine label, title, and content
          admonition_html = ''
          admonition_html += "#{label}\n"
          admonition_html += "#{title_html}\n" if title_html
          admonition_html += content

          %(<div#{attrs}>\n#{admonition_html}\n</div>)
        end

        # Convert HTML admonition div to CoreModel::AnnotationBlock
        def self.to_coradoc(element, _options = {})
          return nil unless element.name == 'div'
          return nil unless element['class']&.include?('admonition')

          # Extract admonition type from class
          type = extract_type(element)
          return nil unless type

          # Extract title if present
          title_elem = element.at_css('.admonition-title')
          title = title_elem&.text&.strip

          # Extract content - all children except label and title
          content_nodes = element.children.reject do |node|
            node == element.at_css('.admonition-label') ||
              node == title_elem ||
              (node.text? && node.text.strip.empty?)
          end

          content = extract_content(content_nodes)

          # Extract ID if present
          id = element['id']

          Coradoc::CoreModel::AnnotationBlock.new(
            annotation_type: type.downcase,
            content: content,
            title: title,
            id: id
          )
        end

        def self.build_attributes(admonition, type)
          attrs = [%( class="admonition admonition-#{type.downcase}")]

          # Add ID if present
          attrs << %( id="#{escape_attribute(admonition.id)}") if admonition.id

          attrs.join
        end

        def self.build_label(type)
          %(<div class="admonition-label">#{escape_html(type)}</div>)
        end

        def self.build_title(admonition)
          return nil unless admonition.title

          title_text = admonition.title.to_s
          return nil if title_text.empty?

          %(<div class="admonition-title">#{escape_html(title_text)}</div>)
        end

        def self.process_content(content)
          return '' if content.nil?

          if content.is_a?(Array)
            # Group consecutive lines into paragraphs, handling inline elements
            result = []
            current_para = []

            content.each do |item|
              case item
              when String
                current_para << item
              else
                # End current paragraph and start a new one
                if current_para.any?
                  result << build_paragraph(current_para)
                  current_para = []
                end
                result << convert_item(item)
              end
            end

            # Don't forget the last paragraph
            result << build_paragraph(current_para) if current_para.any?

            result.compact.join("\n")
          elsif content.is_a?(String)
            "<p>#{escape_html(content)}</p>"
          else
            convert_item(content)
          end
        end

        def self.build_paragraph(items)
          return nil if items.nil? || items.empty?

          # Convert all items to HTML and join them
          content_html = items.map do |item|
            case item
            when String
              escape_html(item)
            else
              convert_content_to_html(item)
            end
          end.join

          return nil if content_html.empty?

          "<p>#{content_html}</p>"
        end

        def self.convert_item(item)
          case item
          when String
            "<p>#{escape_html(item)}</p>"
          else
            convert_content_to_html(item)
          end
        end

        def self.extract_type(element)
          return nil unless element['class']

          # Extract type from class like "admonition-note", "admonition-warning", etc.
          classes = element['class'].split
          type_class = classes.find { |c| c.start_with?('admonition-') && c != 'admonition' }
          return nil unless type_class

          type_class.sub(/^admonition-/, '').upcase
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
