# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      module Inline
        # Classification of inline handlers.
        SIMPLE_MARK_TYPES = {
          CoreModel::BoldElement => Mark::Bold,
          CoreModel::ItalicElement => Mark::Italic,
          CoreModel::MonospaceElement => Mark::Monospace,
          CoreModel::UnderlineElement => Mark::Underline,
          CoreModel::StrikethroughElement => Mark::Strikethrough,
          CoreModel::SubscriptElement => Mark::Subscript,
          CoreModel::SuperscriptElement => Mark::Superscript,
          CoreModel::HighlightElement => Mark::Highlight,
          CoreModel::TermElement => Mark::Bold,
        }.freeze

        def self.process(element, context:)
          return [] unless element

          children = inline_children_for(element)

          children.flat_map do |child|
            process_child(child, context)
          end
        end

        def self.process_child(child, context)
          case child
          when CoreModel::TextContent
            return [] if child.text.nil? || child.text.empty?
            [context.text_node(child.text)]
          when CoreModel::InlineElement
            [dispatch_inline(child, context)].compact
          when CoreModel::FootnoteReference
            [context.resolve_footnote_reference(child)]
          when CoreModel::Block, CoreModel::StructuralElement
            result = context.registry.handle(child, context: context)
            return [] unless result

            value, concat = result
            return [] unless value

            if concat
              Array(value)
            else
              [value].compact
            end
          when CoreModel::Image
            [Handlers::Image.call(child, context: context)]
          else
            []
          end
        end

        def self.call(element, context:)
          dispatch_inline(element, context)
        end

        def self.text_content(element, context:)
          return nil if element.text.nil? || element.text.empty?
          context.text_node(element.text)
        end

        class << self
          private

          def inline_children_for(element)
            if element.is_a?(CoreModel::InlineElement) ||
               element.is_a?(CoreModel::Block) ||
               element.is_a?(CoreModel::TableCell) ||
               element.is_a?(CoreModel::StructuralElement)
              children = element.children
              return children if children && !children.empty?
            end

            if element.is_a?(CoreModel::InlineElement) ||
               element.is_a?(CoreModel::Block)
              content = element.content
              return [CoreModel::TextContent.new(text: content.to_s)] if content && !content.to_s.empty?
            end

            []
          end

          def dispatch_inline(element, context)
            mark_class = SIMPLE_MARK_TYPES[element.class]
            return build_simple_mark(element, context, mark_class) if mark_class

            case element
            when CoreModel::LinkElement
              build_link_mark(element, context)
            when CoreModel::CrossReferenceElement
              build_xref_mark(element, context)
            when CoreModel::StemElement
              build_stem_mark(element, context)
            when CoreModel::SpanElement
              build_span_mark(element, context)
            when CoreModel::FootnoteElement
              build_footnote_node(element, context)
            when CoreModel::HardLineBreakElement
              Node::SoftBreak.new
            when CoreModel::LineBreakElement
              Node::SoftBreak.new
            when CoreModel::TextElement
              build_text_only(element, context)
            when CoreModel::InlineElement
              handle_generic_inline(element, context)
            end
          end

          def handle_generic_inline(element, context)
            text = element.content.to_s
            return nil if text.empty?

            context.text_node(text)
          end

          def build_simple_mark(element, context, mark_class)
            text = extract_inline_text(element)
            return nil if text.empty?
            context.text_node(text, marks: [mark_class.new])
          end

          def build_link_mark(element, context)
            text = extract_inline_text(element)
            text = element.target.to_s if text.empty? && element.target
            return nil if text.empty?

            context.text_node(text, marks: [Mark::Link.new(href: element.target)])
          end

          def build_xref_mark(element, context)
            text = extract_inline_text(element)
            target = element.target

            display_text = text.empty? ? (target || "") : text
            return nil if display_text.empty?

            context.text_node(display_text, marks: [Mark::CrossReference.new(
              target: target,
              resolved: text.empty? ? nil : text,
            )])
          end

          def build_stem_mark(element, context)
            text = extract_inline_text(element)
            return nil if text.empty?

            context.text_node(text, marks: [Mark::Stem.new(stem_type: element.stem_type)])
          end

          def build_span_mark(element, context)
            text = extract_inline_text(element)
            return nil if text.empty?

            role = element.attr("role")
            context.text_node(text, marks: [Mark::Span.new(role: role)])
          end

          def build_footnote_node(element, context)
            footnote = nil
            if element.is_a?(CoreModel::InlineElement) && element.content
              fn_id = element.attr("id")
              footnote = CoreModel::Footnote.new(
                id: fn_id,
                content: element.content.to_s,
              )
            end

            context.register_footnote(footnote)
          end

          def build_text_only(element, context)
            text = extract_inline_text(element)
            return nil if text.empty?
            context.text_node(text)
          end

          def extract_inline_text(element)
            return element.content.to_s if element.content && !element.content.to_s.empty?

            if element.is_a?(CoreModel::InlineElement) && element.nested_elements
              return element.nested_elements.map { |nested| extract_inline_text(nested) }.join
            end

            if (element.is_a?(CoreModel::InlineElement) || element.is_a?(CoreModel::Block)) && element.children && !element.children.empty?
              return element.children.map do |child|
                case child
                when CoreModel::TextContent then child.text.to_s
                when CoreModel::InlineElement then extract_inline_text(child)
                else ""
                end
              end.join
            end

            ""
          end
        end
      end
    end
  end
end
