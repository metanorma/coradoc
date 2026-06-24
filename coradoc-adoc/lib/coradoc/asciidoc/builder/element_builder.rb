# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    class Builder
      module ElementBuilder
        def build_header(ast)
          header_ast = ast[:header] || ast

          Coradoc::CoreModel::HeaderElement.new(
            title: extract_text_content(header_ast[:title]),
            id: header_ast[:id]
          )
        end

        def build_section(ast)
          section_ast = ast[:section] || ast

          Coradoc::CoreModel::SectionElement.new(
            title: extract_text_content(section_ast[:title]),
            id: section_ast[:id],
            level: extract_level(section_ast),
            children: build_section_contents(section_ast[:contents]) +
                      build_subsections(section_ast[:sections]),
            attributes: build_section_metadata(section_ast[:attribute_list])
          )
        end

        # Convert the AsciiDoc `[style]` / `[role=x]` block header into a
        # CoreModel::Metadata so downstream consumers (coradoc-mirror) can
        # dispatch on `style` to pick a JS section type (annex, abstract, ...).
        # Returns nil when the section had no attribute list — preserves the
        # pre-fix default.
        def build_section_metadata(attribute_list)
          normalized = Coradoc::AsciiDoc::Transformer::AttributeListNormalizer
                       .coerce(attribute_list)
          return nil unless normalized.is_a?(Coradoc::AsciiDoc::Model::AttributeList)

          metadata = Coradoc::CoreModel::Metadata.new
          first_positional = normalized.positional.first
          metadata['style'] = first_positional.value if first_positional
          named_role = normalized.named.find { |n| n.name == 'role' }
          metadata['role'] = named_role.value.first if named_role&.value&.any?
          metadata
        end

        def build_section_contents(contents_ast)
          return [] unless contents_ast

          Array(contents_ast).map { |content| build_element(content) }.compact
        end

        def build_subsections(sections_ast)
          return [] unless sections_ast

          Array(sections_ast).map { |section| build_element(section) }.compact
        end

        def build_line_break(ast)
          Coradoc::CoreModel::Block.new(
            block_semantic_type: 'line_break',
            content: ast[:line_break] || ast['line_break']
          )
        end

        def build_comment_line(ast)
          comment_ast = ast[:comment_line] || ast['comment_line'] || ast

          Coradoc::CoreModel::CommentBlock.new(
            content: comment_ast[:comment_text] || comment_ast['comment_text']
          )
        end

        def build_comment_block(ast)
          comment_ast = ast[:comment_block] || ast['comment_block'] || ast

          Coradoc::CoreModel::CommentBlock.new(
            content: comment_ast[:comment_text] || comment_ast['comment_text']
          )
        end

        def build_include(ast)
          include_ast = ast[:include] || ast['include'] || ast

          Coradoc::CoreModel::Block.new(
            block_semantic_type: 'include',
            content: include_ast[:path] || include_ast['path']
          )
        end

        def build_table(ast)
          table_ast = ast[:table] || ast['table'] || ast

          Coradoc::CoreModel::Table.new(
            title: table_ast[:title] || table_ast['title'],
            id: table_ast[:id] || table_ast['id'],
            rows: table_ast[:rows] || table_ast['rows'] || []
          )
        end

        def build_unparsed(ast)
          Coradoc::CoreModel::Block.new(
            block_semantic_type: 'unparsed',
            content: (ast[:unparsed] || ast['unparsed']).to_s
          )
        end

        def build_tag(ast)
          tag_ast = ast[:tag] || ast['tag'] || ast

          Coradoc::CoreModel::Block.new(
            block_semantic_type: 'tag',
            content: tag_ast[:name] || tag_ast['name']
          )
        end

        def build_bibliography_entry(ast)
          bib_ast = ast[:bibliography_entry] || ast['bibliography_entry'] || ast

          Coradoc::CoreModel::BibliographyEntry.new(
            anchor_name: bib_ast[:anchor_name] || bib_ast['anchor_name'],
            document_id: bib_ast[:document_id] || bib_ast['document_id'],
            ref_text: bib_ast[:ref_text] || bib_ast['ref_text']
          )
        end

        def build_generic_element(ast)
          Coradoc::CoreModel::Block.new(
            block_semantic_type: 'unknown',
            content: ast.to_s
          )
        end

        def build_attribute(ast)
          Coradoc::CoreModel::ElementAttribute.new(
            name: ast[:key],
            value: ast[:value]
          )
        end
      end
    end
  end
end
