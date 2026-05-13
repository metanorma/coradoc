# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Admonition < Base
        def self.to_html(admonition, _options = {})
          return '' unless admonition

          type = admonition.annotation_type ? admonition.annotation_type.to_s.upcase : 'NOTE'

          attrs = { class: "admonition admonition-#{type.downcase}" }
          attrs[:id] = admonition.id if admonition.id

          children = []

          children << NodeBuilder.build(:div, escape_html(type), class: 'admonition-label')

          if admonition.title && !admonition.title.to_s.empty?
            children << NodeBuilder.build(:div, escape_html(admonition.title.to_s),
                                          class: 'admonition-title')
          end

          content = process_content(admonition.content)
          children << content unless content.empty?

          NodeBuilder.build(:div, children, **attrs).to_html
        end

        def self.to_coradoc(element, _options = {})
          return nil unless element.name == 'div'
          return nil unless element['class']&.include?('admonition')

          type = extract_type(element)
          return nil unless type

          title_elem = element.at_css('.admonition-title')
          title = title_elem&.text&.strip

          content_nodes = element.children.reject do |node|
            node == element.at_css('.admonition-label') ||
              node == title_elem ||
              (node.text? && node.text.strip.empty?)
          end

          content = extract_content(content_nodes)

          Coradoc::CoreModel::AnnotationBlock.new(
            annotation_type: type.downcase,
            content: content,
            title: title,
            id: element['id']
          )
        end

        def self.process_content(content)
          return '' if content.nil?

          if content.is_a?(Array)
            result = []
            current_para = []

            content.each do |item|
              case item
              when String
                current_para << item
              else
                if current_para.any?
                  result << build_paragraph(current_para)
                  current_para = []
                end
                result << convert_item(item)
              end
            end

            result << build_paragraph(current_para) if current_para.any?

            result.compact.join("\n")
          elsif content.is_a?(String)
            NodeBuilder.build(:p, escape_html(content)).to_html
          else
            convert_item(content)
          end
        end

        def self.build_paragraph(items)
          return nil if items.nil? || items.empty?

          content_html = items.map do |item|
            case item
            when String
              escape_html(item)
            else
              convert_content_to_html(item)
            end
          end.join

          return nil if content_html.empty?

          NodeBuilder.build(:p, content_html).to_html
        end

        def self.convert_item(item)
          case item
          when String
            NodeBuilder.build(:p, escape_html(item)).to_html
          else
            convert_content_to_html(item)
          end
        end

        def self.extract_type(element)
          return nil unless element['class']

          classes = element['class'].split
          type_class = classes.find { |c| c.start_with?('admonition-') && c != 'admonition' }
          return nil unless type_class

          type_class.sub(/^admonition-/, '').upcase
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
