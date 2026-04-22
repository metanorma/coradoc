# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for CoreModel::Block (source) to HTML <pre><code>
      class Source < Base
        # Convert CoreModel::Block (source) to HTML <pre><code>
        def self.to_html(source, _options = {})
          return '' unless source

          # Build title if present
          title_html = build_title(source)

          # Build code attributes with language
          code_attrs = build_code_attributes(source)

          # Build pre attributes
          pre_attrs = build_pre_attributes(source)

          # Process source content
          content = process_content(source.content)

          # Combine into source block
          source_html = ''
          source_html += "#{title_html}\n" if title_html
          source_html += %(<pre#{pre_attrs}><code#{code_attrs}>#{content}</code></pre>)

          if title_html
            %(<div class="source-block">\n#{source_html}\n</div>)
          else
            source_html
          end
        end

        # Convert HTML <pre><code> to CoreModel::Block (source)
        def self.to_coradoc(element, _options = {})
          # Handle <div class="source-block"><pre><code>, <pre><code>, or <code>
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

          # Extract title if in source-block wrapper
          title = if element.name == 'div'
                    title_elem = element.at_css('.source-title')
                    title_elem&.text&.strip
                  end

          # Extract language from class
          language = extract_language(code_elem)

          # Extract content
          content = code_elem.text

          # Extract ID if present
          id = code_elem['id'] || element['id']

          Coradoc::CoreModel::Block.new(
            delimiter_type: '----',
            content: content,
            title: title,
            id: id,
            language: language
          )
        end

        def self.build_code_attributes(source)
          attrs = []

          # Add language class if present
          lang = source.language

          attrs << %( class="language-#{escape_attribute(lang)}") if lang && !lang.empty?

          # Add ID if present
          attrs << %( id="#{escape_attribute(source.id)}") if source.id

          attrs.join
        end

        def self.build_pre_attributes(_source)
          %( class="source")
        end

        def self.build_title(source)
          return nil unless source.title

          title_text = source.title.to_s
          return nil if title_text.empty?

          %(<div class="source-title">#{escape_html(title_text)}</div>)
        end

        def self.process_content(content)
          return '' if content.nil?

          # For source code, preserve the content exactly
          if content.is_a?(String)
            escape_html(content)
          elsif content.is_a?(Array)
            # Join array items with newlines
            content.map { |line| escape_html(line.to_s) }.join("\n")
          else
            escape_html(content.to_s)
          end
        end

        def self.extract_language(element)
          return nil unless element['class']

          # Extract language from class like "language-ruby", "lang-python", etc.
          classes = element['class'].split
          lang_class = classes.find { |c| c.start_with?('language-', 'lang-') }
          return nil unless lang_class

          lang_class.sub(/^(language-|lang-)/, '')
        end
      end

      # Converter for SourceCode blocks
      #
      # SourceCode models use the `lines` attribute, while Source models use `content`.
      # This converter inherits from Source and handles the lines attribute properly.
      class SourceCode < Source
        # The parent Source class already handles both content and lines attributes
        # after our recent update, so we just need to inherit.
      end
    end
  end
end
