# frozen_string_literal: true

module Coradoc
  module Markdown
    module Transform
      module StructuralTransformer
        class << self
          def transform_structural_element(element)
            case element
            when CoreModel::DocumentElement
              transform_document(element)
            when CoreModel::SectionElement
              transform_section(element)
            when CoreModel::PreambleElement
              transform_preamble(element)
            when CoreModel::HeaderElement
              transform_header(element)
            else
              transform_generic_element(element)
            end
          end

          def transform_document(doc)
            blocks = Array(doc.children)
                     .flat_map { |child| FromCoreModel.flatten_transform_result(FromCoreModel.transform(child)) }
                     .compact

            Coradoc::Markdown::Document.new(
              id: doc.id,
              blocks: blocks
            )
          end

          def transform_section(section)
            blocks = []
            blocks << Coradoc::Markdown::Heading.new(
              level: section.level || 1,
              text: section.title.to_s
            )
            child_blocks = Array(section.children)
                           .flat_map { |child| FromCoreModel.flatten_transform_result(FromCoreModel.transform(child)) }
                           .compact
            blocks.concat(child_blocks)
            blocks
          end

          def transform_preamble(preamble)
            Array(preamble.children)
              .flat_map { |child| FromCoreModel.flatten_transform_result(FromCoreModel.transform(child)) }
              .compact
          end

          def transform_header(header)
            level = header.level || 1
            Coradoc::Markdown::Heading.new(
              level: level,
              text: header.title.to_s
            )
          end

          def transform_generic_element(element)
            blocks = Array(element.children)
                     .flat_map { |child| FromCoreModel.flatten_transform_result(FromCoreModel.transform(child)) }
                     .compact

            Coradoc::Markdown::Document.new(
              id: element.id,
              blocks: blocks
            )
          end

          def transform_bibliography(bib)
            entries = Array(bib.entries).map { |e| FromCoreModel.transform(e) }
            blocks = []
            blocks << Coradoc::Markdown::Heading.new(level: 2, text: bib.title.to_s) if bib.title
            blocks.concat(entries)
            Coradoc::Markdown::Document.new(id: bib.id, blocks: blocks)
          end

          def transform_bibliography_entry(entry)
            FromCoreModel.transform_bibliography_entry(entry)
          end
end

        # Register with FromCoreModel
        FromCoreModel.register(CoreModel::StructuralElement, method(:transform_structural_element))
        FromCoreModel.register(CoreModel::Bibliography, method(:transform_bibliography))
        FromCoreModel.register(CoreModel::BibliographyEntry, method(:transform_bibliography_entry))
        FromCoreModel.register(CoreModel::Toc, ->(_m) { Coradoc::Markdown::Extension.toc })
        FromCoreModel.register(CoreModel::TocEntry, ->(m) { Coradoc::Markdown::Text.new(content: m.title.to_s) })
      end
    end
  end
end
