# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      module Rules
        # Transforms w:hyperlink elements to CoreModel::InlineElement (link).
        #
        # External hyperlinks have r:id (URL). Internal links have w:anchor
        # (bookmark reference). Both are captured in the target attribute.
        class HyperlinkRule < Rule
          def matches?(element)
            defined?(Uniword::Wordprocessingml::Hyperlink) &&
              element.is_a?(Uniword::Wordprocessingml::Hyperlink)
          end

          def apply(hyperlink, context)
            content = extract_content(hyperlink, context)
            text = flatten_to_string(content)

            Coradoc::CoreModel::InlineElement.new(
              format_type: 'link',
              target: resolve_target(hyperlink),
              content: text
            )
          end

          private

          def resolve_target(hyperlink)
            # External link (URL stored in r:id)
            return hyperlink.id if hyperlink.id && !hyperlink.id.empty?

            # Internal link (bookmark anchor)
            "##{hyperlink.anchor}" if hyperlink.anchor
          end

          def extract_content(hyperlink, context)
            return [] if hyperlink.runs.nil?

            hyperlink.runs.map { |r| context.transform(r) }.compact
          end

          def flatten_to_string(content)
            case content
            when Array
              content.map { |c| c.is_a?(String) ? c : c.to_s }.join
            when String
              content
            else
              content.to_s
            end
          end
        end
      end
    end
  end
end
