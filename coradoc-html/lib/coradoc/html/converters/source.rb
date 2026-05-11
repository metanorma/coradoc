# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Source < Base
        def self.to_html(source, _options = {})
          return '' unless source

          code_attrs = {}
          lang = source.language
          code_attrs[:class] = "language-#{lang}" if lang && !lang.empty?
          code_attrs[:id] = source.id if source.id

          content = process_content(source.content)

          code_node = NodeBuilder.build(:code, content, **code_attrs)
          pre_node = NodeBuilder.build(:pre, code_node, class: 'source')

          if source.title && !source.title.to_s.empty?
            title_node = NodeBuilder.build(:div, escape_html(source.title.to_s), class: 'source-title')
            NodeBuilder.build(:div, [title_node, pre_node], class: 'source-block').to_html
          else
            pre_node.to_html
          end
        end

        def self.to_coradoc(element, _options = {})
          code_elem = if element.name == 'div' && element['class']&.include?('source-block')
                        element.at_css('code')
                      elsif element.name == 'pre'
                        element.at_css('code')
                      elsif element.name == 'code'
                        element
                      else
                        return nil
                      end

          return nil unless code_elem

          title = if element.name == 'div'
                    title_elem = element.at_css('.source-title')
                    title_elem&.text&.strip
                  end

          language = extract_language(code_elem)
          content = code_elem.text
          id = code_elem['id'] || element['id']

          Coradoc::CoreModel::SourceBlock.new(
            content: content,
            title: title,
            id: id,
            language: language
          )
        end

        def self.process_content(content)
          return '' if content.nil?

          if content.is_a?(String)
            escape_html(content)
          elsif content.is_a?(Array)
            content.map { |line| escape_html(line.to_s) }.join("\n")
          else
            escape_html(content.to_s)
          end
        end

        def self.extract_language(element)
          return nil unless element['class']

          classes = element['class'].split
          lang_class = classes.find { |c| c.start_with?('language-', 'lang-') }
          return nil unless lang_class

          lang_class.sub(/^(language-|lang-)/, '')
        end
      end

      class SourceCode < Source
      end
    end
  end
end
