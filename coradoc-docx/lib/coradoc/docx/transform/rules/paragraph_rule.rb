# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      module Rules
        # Transforms regular paragraphs to CoreModel::Block.
        #
        # Handles paragraph-style detection for block types:
        # quote, source, literal, example, or plain paragraph.
        #
        # This is the default rule for paragraphs. The orchestrator dispatches
        # heading and list item paragraphs directly, so this rule only sees
        # regular paragraphs.
        class ParagraphRule < Rule
          include OrderedContent

          def priority
            0
          end

          def matches?(element)
            defined?(Uniword::Wordprocessingml::Paragraph) &&
              element.is_a?(Uniword::Wordprocessingml::Paragraph)
          end

          def apply(paragraph, context)
            role = context.style_resolver.role_from_style(paragraph)
            block_type = block_type_for(role)

            children = transform_paragraph_content(paragraph, context)
            id = extract_bookmark_id(paragraph)

            block = CoreModel::Block.new(
              element_type: block_type,
              content: extract_plain_text(children)
            )
            block.children = children
            block.id = id if id
            block
          end

          private

          def block_type_for(role)
            case role
            when :quote then 'quote'
            when :source then 'source'
            when :literal then 'literal'
            when :example then 'example'
            else 'paragraph'
            end
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
