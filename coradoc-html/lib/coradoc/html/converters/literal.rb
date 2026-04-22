# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for CoreModel::Block (literal) to HTML <pre>
      class Literal < Base
        # Convert CoreModel::Block (literal) to HTML <pre>
        def self.to_html(literal, _options = {})
          return '' unless literal

          # Build pre attributes
          attrs = build_attributes(literal)

          # Build title if present
          title_html = build_title(literal)

          # Process literal content - preserve exact formatting
          content = process_content(literal.content)

          # Combine title and content
          literal_html = ''
          literal_html += "#{title_html}\n" if title_html
          literal_html += %(<pre#{attrs}>#{content}</pre>)

          if title_html
            %(<div class="literal-block">\n#{literal_html}\n</div>)
          else
            literal_html
          end
        end

        # Convert HTML <pre> to CoreModel::Block (literal)
        def self.to_coradoc(element, _options = {})
          # Handle both <pre> and <div class="literal-block"><pre>
          pre_elem = if element.name == 'div' && element['class']&.include?('literal-block')
                       element.at_css('pre')
                     elsif element.name == 'pre'
                       # Only convert if it's a literal (no code class)
                       return nil if element['class']&.include?('code')

                       element
                     else
                       return nil
                     end

          return nil unless pre_elem

          # Extract title if in literal-block wrapper
          title = if element.name == 'div'
                    title_elem = element.at_css('.literal-title')
                    title_elem&.text&.strip
                  end

          # Extract content
          content = pre_elem.text

          # Extract ID if present
          id = pre_elem['id'] || element['id']

          Coradoc::CoreModel::Block.new(
            delimiter_type: '....',
            content: content,
            title: title,
            id: id
          )
        end

        def self.build_attributes(literal)
          attrs = [%( class="literal")]

          # Add ID if present
          attrs << %( id="#{escape_attribute(literal.id)}") if literal.id

          attrs.join
        end

        def self.build_title(literal)
          return nil unless literal.title

          title_text = literal.title.to_s
          return nil if title_text.empty?

          %(<div class="literal-title">#{escape_html(title_text)}</div>)
        end

        def self.process_content(content)
          return '' if content.nil?

          # For literal, preserve the content exactly as-is
          if content.is_a?(String)
            escape_html(content)
          elsif content.is_a?(Array)
            # Join array items with newlines
            content.map { |line| escape_html(line.to_s) }.join("\n")
          else
            escape_html(content.to_s)
          end
        end
      end
    end
  end
end
