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
              canonical = Coradoc::AsciiDoc::Transform::ElementTransformers::AdmonitionStyles.canonicalize(admonition.type) || admonition.type.to_s
              children = ToCoreModel.transform_inline_content(admonition.content)
              block = Coradoc::CoreModel::AnnotationBlock.new(
                annotation_type: canonical,
                content: ToCoreModel.extract_text_content(admonition.content)
              )
              block.children = children
              block
            end

            def transform_image(image)
              Coradoc::CoreModel::Image.new(**image_attributes(image))
            end

            def image_attributes(image)
              {
                src: normalize_image_src(image.src),
                alt: image.alt, title: image.title, caption: image.caption,
                width: image.width, height: image.height,
                link: image.link, role: image.role,
                inline: image.is_a?(Coradoc::AsciiDoc::Model::Image::InlineImage)
              }
            end

            def normalize_image_src(src)
              s = src.to_s
              s.start_with?(':') ? s[1..] : s
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
