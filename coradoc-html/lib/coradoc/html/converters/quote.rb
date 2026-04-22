# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for CoreModel::Block (quote) to HTML <blockquote>
      class Quote < Base
        # Convert CoreModel::Block (quote) to HTML <blockquote>
        def self.to_html(quote, _options = {})
          return '' unless quote

          # Build blockquote attributes
          attrs = build_attributes(quote)

          # Process quote content
          content = process_content(quote.content)

          # Build attribution if present
          attribution = build_attribution(quote)

          # Combine content and attribution
          quote_html = content
          quote_html += "\n#{attribution}" if attribution

          "<blockquote#{attrs}>\n#{quote_html}\n</blockquote>"
        end

        # Convert HTML <blockquote> to CoreModel::Block (quote)
        def self.to_coradoc(element, _options = {})
          return nil unless element.name == 'blockquote'

          # Extract content - all children except cite/footer
          content_nodes = element.children.reject do |node|
            %w[cite footer].include?(node.name)
          end

          content = extract_content(content_nodes)

          # Extract attribution from <cite> or <footer>
          cite_elem = element.at_css('cite, footer')
          attribution = cite_elem&.text&.strip

          # Extract ID if present
          id = element['id']

          Coradoc::CoreModel::Block.new(
            delimiter_type: '____',
            content: content,
            id: id,
            metadata: attribution ? { attribution: attribution } : {}
          )
        end

        def self.build_attributes(quote)
          attrs = []

          # Add ID if present
          attrs << %( id="#{escape_attribute(quote.id)}") if quote.id

          attrs.join
        end

        def self.process_content(content)
          return '' if content.nil?

          if content.is_a?(Array)
            content.map { |item| convert_item(item) }.join("\n")
          elsif content.is_a?(String)
            "<p>#{escape_html(content)}</p>"
          else
            convert_item(content)
          end
        end

        def self.convert_item(item)
          case item
          when String
            "<p>#{escape_html(item)}</p>"
          else
            # Use centralized content conversion
            convert_content_to_html(item)
          end
        end

        def self.build_attribution(quote)
          # Check metadata for attribution
          attribution_text = quote.metadata&.dig(:attribution)
          return nil unless attribution_text

          attribution_text = attribution_text.to_s.strip
          return nil if attribution_text.empty?

          %(<footer>#{escape_html(attribution_text)}</footer>)
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
