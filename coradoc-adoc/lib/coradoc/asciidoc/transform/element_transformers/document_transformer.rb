# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      module ElementTransformers
        class DocumentTransformer
          class << self
            def transform_document(doc)
              title_text = ToCoreModel.extract_title_text(doc.header&.title)
              attributes = ToCoreModel.extract_document_attributes(doc)
              children = ToCoreModel.transform(doc.sections || doc.contents || [])
              children = CalloutMerger.call(children)
              children = prepend_frontmatter(children, doc.frontmatter)

              Coradoc::CoreModel::DocumentElement.new(
                id: doc.id,
                title: title_text,
                attributes: attributes,
                children: children
              )
            end

            # If the AsciiDoc document carried raw frontmatter text, parse
            # it via Codec into a typed FrontmatterBlock and prepend it so
            # it participates in the standard block pipeline. Codec is the
            # single source of truth for YAML parsing (DRY/MECE).
            def prepend_frontmatter(children, frontmatter_text)
              return children if frontmatter_text.nil? || frontmatter_text.strip.empty?

              block = Coradoc::CoreModel::FrontmatterBlock::Codec.from_yaml(frontmatter_text)
              [block, *children]
            end

            def transform_section(section, parent_id: nil)
              title_text = ToCoreModel.extract_title_text(section.title)
              section_id = section.id || Coradoc::CoreModel::IdGenerator.generate_from_title(
                title_text, parent_id: parent_id
              )

              content_children = ToCoreModel.transform(section.contents || [])
              content_children = CalloutMerger.call(content_children)
              nested_sections = (section.sections || []).map do |child|
                transform_section(child, parent_id: section_id)
              end

              Coradoc::CoreModel::SectionElement.new(
                id: section_id,
                level: section.level,
                title: title_text,
                children: content_children + nested_sections
              )
            end
          end
        end
      end
    end
  end
end
