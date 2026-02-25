# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      module Rules
        # Transforms list-item paragraphs to CoreModel::ListItem.
        #
        # Each paragraph with numPr (numbering properties) becomes a ListItem.
        # The ToCoreModel orchestrator groups consecutive items with the same
        # numId into a single ListBlock.
        #
        # Children are stored as InlineElement objects (via transform_paragraph_content)
        # while content is the plain text representation.
        #
        # This rule is NOT registered in the RuleRegistry — the orchestrator
        # dispatches directly after checking style_resolver.list_item?.
        class ListItemRule < Rule
          include OrderedContent

          def matches?(_element)
            false # Never auto-matched; orchestrator dispatches directly
          end

          def apply(paragraph, context)
            ilvl = paragraph.properties&.ilvl.to_i

            children = transform_paragraph_content(paragraph, context)

            item = CoreModel::ListItem.new(
              marker: marker_for(ilvl),
              content: extract_plain_text(children)
            )
            item.instance_variable_set(:@children, children)
            item
          end

          private

          def marker_for(level)
            level.zero? ? '*' : '*' * (level + 1)
          end
        end
      end
    end
  end
end
