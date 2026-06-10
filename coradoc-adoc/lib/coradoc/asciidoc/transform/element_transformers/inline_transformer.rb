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
                content: ToCoreModel.extract_text_content(inline.content)
              )
            end

            def transform_inline_text(inline, format_type)
              klass = Coradoc::CoreModel::InlineElement.format_type_class(format_type)
              klass.new(
                content: inline.text.to_s
              )
            end

            def transform_inline_footnote(footnote)
              parsed_content = ToCoreModel.parse_and_transform_inline(footnote.text.to_s)
              Coradoc::CoreModel::FootnoteElement.new(
                target: footnote.id,
                content: parsed_content
              )
            end

            def transform_link(link)
              Coradoc::CoreModel::LinkElement.new(
                target: link.path,
                content: link.name || link.path
              )
            end

            def transform_cross_reference(xref)
              Coradoc::CoreModel::CrossReferenceElement.new(
                target: xref.href,
                content: xref.args&.first || xref.href
              )
            end

            def transform_stem(stem)
              Coradoc::CoreModel::StemElement.new(
                content: stem.content,
                stem_type: stem.type || 'stem'
              )
            end
          end
        end
      end
    end
  end
end
