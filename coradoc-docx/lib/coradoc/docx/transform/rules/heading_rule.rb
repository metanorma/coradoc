# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      module Rules
        # Transforms heading paragraphs to CoreModel::StructuralElement.
        #
        # Heading detection uses StyleResolver which checks pStyle values
        # (like "Heading1", "heading 2") and outline levels.
        #
        # This rule is NOT registered in the RuleRegistry — instead, the
        # ToCoreModel orchestrator dispatches to it directly after checking
        # the style resolver. This avoids the problem of matches() needing
        # context to determine if a paragraph is a heading.
        class HeadingRule < Rule
          include OrderedContent

          def matches?(_element)
            false # Never auto-matched; orchestrator dispatches directly
          end

          def apply(paragraph, context)
            level = context.style_resolver.heading_level(paragraph) || 1
            title = extract_title(paragraph, context)
            id = extract_bookmark_id(paragraph)

            CoreModel::StructuralElement.new(
              element_type: 'section',
              level: level,
              title: title,
              id: id
            )
          end

          private

          def extract_title(paragraph, context)
            children = transform_paragraph_content(paragraph, context)
            extract_plain_text(children)
          end

          def extract_bookmark_id(paragraph)
            starts = paragraph.bookmark_starts
            return nil if starts.nil? || starts.empty?

            starts.first.id&.to_s
          end
        end
      end
    end
  end
end
