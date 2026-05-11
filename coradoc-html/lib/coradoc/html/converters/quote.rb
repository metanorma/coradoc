# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Quote < Base
        def self.to_html(quote, _options = {})
          return '' unless quote

          attrs = {}
          attrs[:id] = quote.id if quote.id

          content = process_content(quote.content)
          children_html = content

          attribution = build_attribution(quote)
          children_html += "\n#{attribution}" if attribution

          NodeBuilder.build(:blockquote, children_html, **attrs).to_html
        end

        def self.to_coradoc(element, _options = {})
          return nil unless element.name == 'blockquote'

          content_nodes = element.children.reject do |node|
            %w[cite footer].include?(node.name)
          end

          content = extract_content(content_nodes)

          cite_elem = element.at_css('cite, footer')
          attribution = cite_elem&.text&.strip

          Coradoc::CoreModel::QuoteBlock.new(
            content: content,
            id: element['id'],
            attribution: attribution
          )
        end

        def self.process_content(content)
          return '' if content.nil?

          if content.is_a?(Array)
            content.map { |item| convert_item(item) }.join("\n")
          elsif content.is_a?(String)
            NodeBuilder.build(:p, escape_html(content)).to_html
          else
            convert_item(content)
          end
        end

        def self.convert_item(item)
          case item
          when String
            NodeBuilder.build(:p, escape_html(item)).to_html
          else
            convert_content_to_html(item)
          end
        end

        def self.build_attribution(quote)
          attribution_text = quote.metadata&.dig(:attribution)
          return nil unless attribution_text
          return nil if attribution_text.to_s.strip.empty?

          NodeBuilder.build(:footer, escape_html(attribution_text.to_s.strip)).to_html
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
