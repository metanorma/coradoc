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
              children = insert_title_heading_after_frontmatter(children, title_text)

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

            # Per the AsciiDoc spec, the document title (`= Title`) is the
            # document's level-0 heading. Asciidoctor renders it as an
            # <h1> at the top of the body by default. Emit a HeaderElement
            # at level 0 so consumers that walk the body's children see the
            # title (the standard ProseMirror/HTML rendering pattern)
            # instead of having to read Document.title separately.
            #
            # The title attribute on DocumentElement is preserved for
            # consumers that read it directly. The title heading is placed
            # after any FrontmatterBlock (frontmatter is metadata that
            # precedes the body).
            def insert_title_heading_after_frontmatter(children, title_text)
              return children if title_text.nil? || title_text.strip.empty?

              title_heading = Coradoc::CoreModel::HeaderElement.new(
                level: 0,
                title: title_text,
                content: title_text
              )
              frontmatter_count = children.count do |child|
                child.is_a?(Coradoc::CoreModel::FrontmatterBlock)
              end
              children.insert(frontmatter_count, title_heading)
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
                children: content_children + nested_sections,
                attributes: section_metadata_from(section)
              )
            end

            # Delegates to Transform::AttributeListToMetadata for the typed
            # Model::AttributeList -> CoreModel::Metadata conversion. The
            # helper handles the nil/non-AttributeList guard and is the
            # single source of truth shared with Builder::ElementBuilder.
            def section_metadata_from(section)
              Coradoc::AsciiDoc::Transform::AttributeListToMetadata
                .call(section.attribute_list)
            end
          end
        end
      end
    end
  end
end
