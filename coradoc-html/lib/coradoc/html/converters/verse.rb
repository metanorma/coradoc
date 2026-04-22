# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for CoreModel::Block (verse) to HTML <div class="verse">
      class Verse < Base
        # Convert CoreModel::Block (verse) to HTML <div class="verse">
        def self.to_html(verse, _options = {})
          return '' unless verse

          # Build div attributes
          attrs = build_attributes(verse)

          # Build title if present
          title_html = build_title(verse)

          # Build attribution if present
          attribution = build_attribution(verse)

          # Process verse content - preserve line breaks
          content = process_content(verse.content)

          # Combine title, content, and attribution
          verse_html = ''
          verse_html += "#{title_html}\n" if title_html
          verse_html += %(<pre class="verse-content">#{content}</pre>)
          verse_html += "\n#{attribution}" if attribution

          %(<div#{attrs}>\n#{verse_html}\n</div>)
        end

        # Convert HTML <div class="verse"> to CoreModel::Block (verse)
        def self.to_coradoc(element, _options = {})
          return nil unless element.name == 'div'
          return nil unless element['class']&.include?('verse')

          # Extract title if present
          title_elem = element.at_css('.verse-title')
          title = title_elem&.text&.strip

          # Extract content from <pre class="verse-content">
          content_elem = element.at_css('.verse-content, pre')
          content = content_elem&.text || ''

          # Extract attribution from <cite> or <footer>
          cite_elem = element.at_css('cite, footer')
          attribution = cite_elem&.text&.strip

          # Extract ID if present
          id = element['id']

          Coradoc::CoreModel::Block.new(
            delimiter_type: '[verse]',
            content: content,
            title: title,
            id: id,
            metadata: attribution ? { attribution: attribution } : {}
          )
        end

        def self.build_attributes(verse)
          attrs = [%( class="verse")]

          # Add ID if present
          attrs << %( id="#{escape_attribute(verse.id)}") if verse.id

          attrs.join
        end

        def self.build_title(verse)
          return nil unless verse.title

          title_text = verse.title.to_s
          return nil if title_text.empty?

          %(<div class="verse-title">#{escape_html(title_text)}</div>)
        end

        def self.build_attribution(verse)
          attribution_text = verse.metadata&.dig(:attribution)
          return nil unless attribution_text

          attribution_text = attribution_text.to_s.strip
          return nil if attribution_text.empty?

          %(<footer>#{escape_html(attribution_text)}</footer>)
        end

        def self.process_content(content)
          return '' if content.nil?

          # For verse, preserve the content as-is with line breaks
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
