# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      module ElementTransformers
        class InlineTransformer
          class << self
            def transform_inline(inline, format_type)
              klass = Coradoc::CoreModel::InlineElement.format_type_class(format_type)
              klass.new(
                content: ToCoreModel.extract_text_content(inline.content),
                source_line: inline.source_line
              )
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
