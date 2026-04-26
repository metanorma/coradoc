# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      module Rules
        # Transforms w:fldSimple (simple field) elements.
        #
        # Simple fields include page numbers, dates, document properties,
        # and other computed content. This rule extracts the field's text
        # content when available, otherwise produces the instruction text.
        #
        # Common field types:
        # - PAGE → current page number
        # - NUMPAGES → total page count
        # - DATE → current date
        # - TIME → current time
        # - DOCPROPERTY → document property value
        # - TITLE → document title
        # - AUTHOR → document author
        class SimpleFieldRule < Rule
          def matches?(element)
            defined?(Uniword::Wordprocessingml::SimpleField) &&
              element.is_a?(Uniword::Wordprocessingml::SimpleField)
          end

          def apply(field, _context)
            # Try to get the resolved text content first
            text = field_text(field)
            return nil if text.nil? || text.empty?

            # Check if this is a semantic field we should preserve
            instr = field_instruction(field)
            case instr
            when /\A(TITLE|AUTHOR|SUBJECT|KEYWORDS|DOCPROPERTY)\b/i
              # Document metadata — embed as plain text (already resolved)
              text
            when /\A(PAGE|NUMPAGES)\b/i
              # Page layout fields — skip (not semantic)
              nil
            when /\A(HYPERLINK)\b/i
              # Hyperlink field — extract URL and text
              url = extract_hyperlink_url(instr)
              if url
                CoreModel::InlineElement.new(
                  format_type: 'link',
                  content: text,
                  target: url
                )
              else
                text
              end
            when /\A(TOC|PAGEREF|REF|NOTEREF)\b/i
              # TOC / cross-reference fields — skip (print layout)
              nil
            else
              # Generic field — pass through as text
              text
            end
          end

          private

          def field_text(field)
            # SimpleField may have runs with resolved text
            return field.runs.map { |r| r.text&.content.to_s }.join if field.respond_to?(:runs) && field.runs && !field.runs.empty?

            # Fall back to text attribute
            field.respond_to?(:text) ? field.text.to_s : nil
          end

          def field_instruction(field)
            instr = field.respond_to?(:instr) ? field.instr : nil
            instr.to_s
          end

          def extract_hyperlink_url(instr)
            match = instr.match(/HYPERLINK\s+"([^"]+)"/i)
            match&.[](1)
          end
        end
      end
    end
  end
end
