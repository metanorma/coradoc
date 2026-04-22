# frozen_string_literal: true

module Coradoc
  module Docx
    module Transform
      # Orchestrator for OOXML → CoreModel transformation.
      #
      # Walks a Uniword::Wordprocessingml::DocumentRoot tree and dispatches
      # to registered transform rules. Handles:
      #
      # - Style-based heading detection (via StyleResolver)
      # - List grouping (consecutive numPr paragraphs → single ListBlock)
      # - Footnote content collection
      # - Image reference tracking
      # - Bookmark ID propagation
      #
      # Dispatch strategy:
      # - HeadingRule and ListItemRule are dispatched directly by the
      #   orchestrator (they need context for style resolution).
      # - All other element types are dispatched via RuleRegistry.
      #
      # @example Transform a DOCX document
      #   doc = Uniword::DocumentFactory.from_file("input.docx")
      #   core = ToCoreModel.transform(doc)
      #   # => Coradoc::CoreModel::StructuralElement
      class ToCoreModel
        class << self
          def transform(document)
            new.transform(document)
          end
        end

        def transform(document)
          registry = build_registry

          context = Context.new(
            styles_configuration: document.styles_configuration,
            numbering_configuration: document.numbering_configuration,
            footnotes: collect_footnotes(document),
            registry: registry
          )

          @heading_rule = Rules::HeadingRule.new
          @list_item_rule = Rules::ListItemRule.new

          body = document.body
          doc_title = extract_document_title(document, context)
          children = transform_elements(body, context)

          # If the first child is an H1 matching the doc title, skip the
          # duplicate — the document title already captures it
          if doc_title && children.first.is_a?(Coradoc::CoreModel::StructuralElement) &&
             children.first.element_type == 'section' &&
             children.first.title == doc_title &&
             children.first.level == 1
            children.shift
          end

          Coradoc::CoreModel::StructuralElement.new(
            element_type: 'document',
            title: doc_title,
            children: children
          )
        end

        private

        # Walk body elements with list grouping look-ahead
        def transform_elements(body, context)
          return [] unless body

          elements = body_ordered_elements(body)

          result = []
          i = 0

          while i < elements.length
            element = elements[i]

            transformed = dispatch_element(element, i, elements, context)

            case transformed
            when Array
              consumed = transformed.length
              result.concat(transformed.compact)
              i += consumed
            when nil
              i += 1
            else
              result << transformed
              i += 1
            end
          end

          result
        end

        # Dispatch a single body element, handling paragraphs specially
        def dispatch_element(element, index, elements, context)
          # Paragraphs need style-based dispatch (heading, list, or plain)
          return dispatch_paragraph(element, index, elements, context) if paragraph?(element)

          # Tables go through registry directly
          context.transform(element)
        end

        def dispatch_paragraph(paragraph, index, elements, context)
          resolver = context.style_resolver

          # Heading
          return @heading_rule.apply(paragraph, context) if resolver.heading?(paragraph)

          # List item — group consecutive items with same numId
          return group_list(elements, index, context) if resolver.list_item?(paragraph)

          # Regular paragraph (via registry)
          context.transform(paragraph)
        end

        # Collect consecutive list items with the same numId into a ListBlock
        def group_list(elements, start_index, context)
          first = elements[start_index]
          num_id = first.properties&.num_id.to_i
          items = []
          consumed = 0

          idx = start_index
          while idx < elements.length
            para = elements[idx]
            break unless paragraph?(para)
            break unless context.style_resolver.list_item?(para)
            break unless para.properties&.num_id.to_i == num_id

            items << @list_item_rule.apply(para, context)
            consumed += 1
            idx += 1
          end

          list_block = Coradoc::CoreModel::ListBlock.new(
            marker_type: context.numbering_resolver.marker_type(num_id),
            items: items
          )

          # Return array so caller knows how many elements were consumed
          consumed > 1 ? [list_block] + Array.new(consumed - 1, nil) : list_block
        end

        def body_ordered_elements(body)
          order = body.respond_to?(:element_order) ? body.element_order : nil
          return body.elements if order.nil? || order.empty?

          p_idx = tbl_idx = sdt_idx = 0
          order.filter_map do |entry|
            name = entry.respond_to?(:name) ? entry.name : entry.to_s
            case name
            when 'p'
              para = body.paragraphs[p_idx]
              p_idx += 1
              para
            when 'tbl'
              tbl = body.tables[tbl_idx]
              tbl_idx += 1
              tbl
            when 'sdt'
              sdt = body.structured_document_tags&.[](sdt_idx)
              sdt_idx += 1
              sdt
            end
          end
        end

        def paragraph?(element)
          defined?(Uniword::Wordprocessingml::Paragraph) &&
            element.is_a?(Uniword::Wordprocessingml::Paragraph)
        end

        def collect_footnotes(document)
          footnotes = {}

          doc_footnotes = document.footnotes
          if doc_footnotes.is_a?(Hash)
            doc_footnotes.each do |id, fn|
              paragraphs = fn.respond_to?(:content) ? fn.content : []
              footnotes[id.to_s] = Array(paragraphs)
            end
          end

          if defined?(Uniword::Wordprocessingml::Footnotes) &&
             document.footnotes.is_a?(Uniword::Wordprocessingml::Footnotes)
            document.footnotes.footnotes.each do |fn|
              id = fn.id&.to_s
              next unless id

              footnotes[id] = Array(fn.paragraphs || [])
            end
          end

          footnotes
        end

        def extract_document_title(document, context)
          body = document.body
          return nil unless body

          paragraphs = body.paragraphs || []
          paragraphs.each do |para|
            next unless context.style_resolver.heading?(para)
            next unless context.style_resolver.heading_level(para) == 1

            runs = para.runs || []
            return runs.map { |r| r.text&.content.to_s }.join
          end

          nil
        end

        def build_registry
          registry = RuleRegistry.new

          # Only register rules that don't need context for dispatch
          registry.register(Rules::ParagraphRule.new)
          registry.register(Rules::RunRule.new)
          registry.register(Rules::TextRule.new)
          registry.register(Rules::BreakRule.new)
          registry.register(Rules::HyperlinkRule.new)
          registry.register(Rules::ImageRule.new)
          registry.register(Rules::FootnoteRule.new)
          registry.register(Rules::BookmarkRule.new)
          registry.register(Rules::TableRule.new)
          registry.register(Rules::MathRule.new)
          registry.register(Rules::StructuredDocumentTagRule.new)

          registry
        end
      end
    end
  end
end
