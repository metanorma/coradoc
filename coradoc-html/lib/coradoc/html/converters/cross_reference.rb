# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for CoreModel::InlineElement with format_type "xref"
      class CrossReference < Base
        class << self
          # Convert CoreModel::InlineElement (xref) to HTML
          # @param model [Coradoc::CoreModel::InlineElement] CrossReference model
          # @param state [Hash] Conversion state
          # @return [String] HTML anchor tag
          def to_html(model, _state = {})
            href = model.target.to_s
            # Create anchor link to internal reference
            # Format: <a href="#section-id">section-id</a> or with text from content
            text = if model.content&.to_s&.strip != ''
                     model.content.to_s
                   else
                     href
                   end

            # Ensure href starts with # for internal links
            link_href = href.start_with?('#') ? href : "##{href}"

            %(<a href="#{escape_attribute(link_href)}">#{escape_html(text)}</a>)
          end

          # Convert HTML anchor to CoreModel::InlineElement (xref)
          # @param node [Nokogiri::XML::Node] HTML anchor node
          # @param state [Hash] Conversion state
          # @return [Coradoc::CoreModel::InlineElement] CrossReference model
          def to_coradoc(node, _state = {})
            href = node['href'].to_s
            text = node.text.strip

            # Only treat internal links as cross-references
            if href.start_with?('#')
              ref_id = href[1..] # Remove leading #
              content = text.empty? || text == ref_id ? nil : text
              Coradoc::CoreModel::InlineElement.new(
                format_type: 'xref',
                target: ref_id,
                content: content
              )
            else
              # External links become regular links
              Coradoc::CoreModel::InlineElement.new(
                format_type: 'link',
                target: href,
                content: text
              )
            end
          end
        end
      end
    end
  end
end
