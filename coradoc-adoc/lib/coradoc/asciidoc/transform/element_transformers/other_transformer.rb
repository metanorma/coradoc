# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      module ElementTransformers
        class OtherTransformer
          class << self
            def transform_term(term)
              Coradoc::CoreModel::Term.new(
                text: term.term.to_s,
                type: term.type&.to_s || 'preferred',
                lang: term.lang&.to_s || 'en'
              )
            end

            def transform_admonition(admonition)
              children = ToCoreModel.transform_inline_content(admonition.content)
              block = Coradoc::CoreModel::AnnotationBlock.new(
                annotation_type: admonition.type,
                content: ToCoreModel.extract_text_content(admonition.content)
              )
              block.children = children
              block
            end

            def transform_image(image)
              src = image.src.to_s
              src = src[1..] if src.start_with?(':')
              Coradoc::CoreModel::Image.new(
                src: src,
                alt: image.title&.to_s,
                width: image.attributes&.[]('width'),
                height: image.attributes&.[]('height')
              )
            end

            def transform_bibliography(bib)
              entries = Array(bib.entries).map do |entry|
                transform_bibliography_entry(entry)
              end

              Coradoc::CoreModel::Bibliography.new(
                id: bib.id,
                title: bib.title.to_s,
                level: nil,
                entries: entries
              )
            end

            def transform_bibliography_entry(entry)
              Coradoc::CoreModel::BibliographyEntry.new(
                anchor_name: entry.anchor_name,
                document_id: entry.document_id,
                ref_text: entry.ref_text.to_s
              )
            end
          end
        end
      end
    end
  end
end
