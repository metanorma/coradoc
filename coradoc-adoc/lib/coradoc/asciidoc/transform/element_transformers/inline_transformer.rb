# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      module ElementTransformers
        class InlineTransformer
          class << self
            def transform_inline(inline, format_type)
              klass = Coradoc::CoreModel::InlineElement.format_type_class(format_type)
              raw_content = ToCoreModel.extract_text_content(inline.content)

              # Recursively parse the mark's content to recognise nested
              # inline marks (Bug 16B). For `**Per-repo \`file.yml\`**`,
              # the outer Bold's content "Per-repo `file.yml`" is fed
              # back through the inline parser so the inner constrained
              # monospace is recognised. The parsed children are stored
              # on the BoldElement; the Mirror handler walks them to
              # produce ProseMirror's flat text-node-with-marks shape.
              children = parse_nested_inline_children(raw_content)

              if children.any?
                klass.new(
                  content: raw_content,
                  children: children,
                  source_line: inline.source_line
                )
              else
                klass.new(
                  content: raw_content,
                  source_line: inline.source_line
                )
              end
            end

            # Re-parse a mark's raw content string through the inline
            # parser. Returns the list of CoreModel children when the
            # content contains nested inline marks; returns [] when
            # the content is plain text (no nested marks to preserve).
            # The empty return is the recursion terminator — once a
            # mark's content has no further mark characters, the
            # parser produces only TextContent nodes, which we drop
            # in favour of the mark's flat content string.
            def parse_nested_inline_children(text)
              return [] if text.nil? || text.to_s.empty?

              parsed = ToCoreModel.parse_and_transform_inline(text.to_s)
              return [] unless parsed.is_a?(Array)

              has_marks = parsed.any? do |child|
                child.is_a?(Coradoc::CoreModel::InlineElement)
              end
              has_marks ? parsed : []
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
