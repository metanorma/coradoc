# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      # Utility for iterating paragraph content in document order.
      #
      # OOXML paragraphs have separate arrays for runs, hyperlinks, SDTs, etc.
      # but `element_order` (from lutaml-model mixed_content) preserves the
      # interleaved sequence. This module provides a single method to walk
      # paragraph content in the correct order.
      #
      # Used by ParagraphRule, ListItemRule, and HeadingRule.
      module OrderedContent
        # Iterate paragraph inline content in document order.
        #
        # @param paragraph [Uniword::Wordprocessingml::Paragraph]
        # @param context [Context] transform context with registry
        # @return [Array] transformed content (Strings, InlineElements, etc.)
        def transform_paragraph_content(paragraph, context)
          order = paragraph.respond_to?(:element_order) ? paragraph.element_order : nil

          if order && !order.empty?
            transform_ordered(paragraph, order, context)
          else
            transform_sequential(paragraph, context)
          end
        end

        # Flatten children array to plain text string.
        #
        # @param children [Array] mixed content (Strings, InlineElements)
        # @return [String]
        def extract_plain_text(children)
          children.map do |c|
            case c
            when String then c
            when CoreModel::InlineElement then c.content.to_s
            else c.to_s
            end
          end.join
        end

        private

        def transform_ordered(paragraph, order, context)
          counters = {
            r: 0, hyperlink: 0, sdt: 0,
            oMathPara: 0, fldSimple: 0
          }

          result = []
          order.each do |entry|
            name = entry.respond_to?(:name) ? entry.name : entry.to_s
            idx = counters[name]
            counters[name] = idx + 1

            item = case name
                   when 'r'
                     run = paragraph.runs[idx]
                     context.transform(run) if run
                   when 'hyperlink'
                     hl = paragraph.hyperlinks[idx]
                     context.transform(hl) if hl
                   when 'sdt'
                     sdt = paragraph.structured_document_tags&.[](idx)
                     context.transform(sdt) if sdt
                   when 'oMathPara'
                     math = paragraph.o_math_paras&.[](idx)
                     context.transform(math) if math
                   when 'fldSimple'
                     field = paragraph.simple_fields&.[](idx)
                     context.transform(field) if field
                   end

            result << item if item
          end

          result.compact
        end

        def transform_sequential(paragraph, context)
          content = []
          (paragraph.runs || []).each { |r| content << context.transform(r) }
          (paragraph.hyperlinks || []).each { |h| content << context.transform(h) }
          content.compact
        end
      end
    end
  end
end
