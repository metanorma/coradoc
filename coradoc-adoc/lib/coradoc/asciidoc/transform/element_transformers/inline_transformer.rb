# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      module ElementTransformers
        # Owns the recursive re-parse that recognises nested inline marks
        # (Bug 16B). The re-parse re-enters the full inline pipeline:
        #
        #   transform_inline → parse_nested_inline_children
        #     → ToCoreModel.parse_and_transform_inline
        #       → InlineTransformVisitor.visit
        #         → ToCoreModel.transform
        #           → transform_inline (cycle)
        #
        # The cycle terminates when the mark's content has no further
        # inline-mark characters — the parser produces only flat text,
        # `parse_nested_inline_children` returns `[]`, and the mark
        # keeps its flat content shape.
        #
        # The depth guard prevents stack overflow on pathological input
        # (e.g. `*****...*****` with 20+ nesting levels). The realistic
        # maximum is 2–3 levels; the guard allows 5 for headroom.
        module NestedMarkRecognition
          MAX_DEPTH = 5
          THREAD_KEY = :coradoc_nested_mark_depth

          def self.enter
            Thread.current[THREAD_KEY] ||= 0
            Thread.current[THREAD_KEY] += 1
            yield
          ensure
            Thread.current[THREAD_KEY] -= 1
          end

          def self.too_deep?
            (Thread.current[THREAD_KEY] || 0) >= MAX_DEPTH
          end
        end

        class InlineTransformer
          class << self
            def transform_inline(inline, format_type)
              klass = Coradoc::CoreModel::InlineElement.format_type_class(format_type)
              raw_content = ToCoreModel.extract_text_content(inline.content)

              # Recursively parse the mark's content to recognise nested
              # inline marks (Bug 16B). The parsed children are stored on
              # the InlineElement alongside the flat content string for
              # round-trip fidelity.
              #
              # Children is ALWAYS populated — flat marks get
              # [TextContent(content)]; nested marks get the parsed
              # children. This eliminates the dual-shape ambiguity
              # (Bug 16A follow-up).
              children = parse_nested_inline_children(raw_content)
              children = [Coradoc::CoreModel::TextContent.new(text: raw_content)] if children.empty?

              klass.new(
                content: raw_content,
                children: children,
                source_line: inline.source_line
              )
            end

            # Re-parse a mark's raw content string through the inline
            # parser. Returns the list of CoreModel children when the
            # content contains nested inline marks; returns [] when
            # the content is plain text (no nested marks to preserve).
            # The empty return is the recursion terminator.
            #
            # The NestedMarkRecognition module tracks recursion depth
            # per-thread so the cycle is bounded and visible.
            def parse_nested_inline_children(text)
              return [] if text.nil? || text.to_s.empty?
              return [] if NestedMarkRecognition.too_deep?

              NestedMarkRecognition.enter do
                parsed = ToCoreModel.parse_and_transform_inline(text.to_s)
                return [] unless parsed.is_a?(Array)

                has_marks = parsed.any? do |child|
                  child.is_a?(Coradoc::CoreModel::InlineElement)
                end
                has_marks ? parsed : []
              end
            end

            def transform_inline_text(inline, format_type)
              klass = Coradoc::CoreModel::InlineElement.format_type_class(format_type)
              klass.new(
                content: inline.text.to_s,
                source_line: inline.source_line
              )
            end

            def transform_inline_footnote(footnote)
              parsed_content = ToCoreModel.parse_and_transform_inline(footnote.text.to_s)
              Coradoc::CoreModel::FootnoteElement.new(
                target: footnote.id,
                content: parsed_content,
                source_line: footnote.source_line
              )
            end

            def transform_link(link)
              Coradoc::CoreModel::LinkElement.new(
                target: link.path,
                content: link.name || link.path,
                source_line: link.source_line
              )
            end

            def transform_cross_reference(xref)
              Coradoc::CoreModel::CrossReferenceElement.new(
                target: xref.href,
                content: xref.args&.first || xref.href,
                source_line: xref.source_line
              )
            end

            def transform_stem(stem)
              Coradoc::CoreModel::StemElement.new(
                content: stem.content,
                stem_type: stem.type || 'stem',
                source_line: stem.source_line
              )
            end
          end
        end
      end
    end
  end
end
