# frozen_string_literal: true

module Coradoc
  module CoreModel
    class Builder
      # Element building module for Builder
      #
      # Contains methods for building miscellaneous elements from AST structures.
      #
      # @api private
      module ElementBuilder
        # Build header element
        def build_header(ast)
          header_ast = ast[:header] || ast

          {
            type: :header,
            title: header_ast[:title],
            author: header_ast[:author],
            revision: header_ast[:revision],
            id: header_ast[:id]
          }
        end

        # Build section element
        def build_section(ast)
          section_ast = ast[:section] || ast

          {
            type: :section,
            title: section_ast[:title],
            id: section_ast[:id],
            level: extract_level(section_ast),
            contents: build_section_contents(section_ast[:contents]),
            sections: build_subsections(section_ast[:sections]),
            attribute_list: section_ast[:attribute_list]
          }
        end

        # Build section contents
        def build_section_contents(contents_ast)
          return [] unless contents_ast

          Array(contents_ast).map { |content| build_element(content) }.compact
        end

        # Build subsections
        def build_subsections(sections_ast)
          return [] unless sections_ast

          Array(sections_ast).map { |section| build_element(section) }.compact
        end

        # Build line break element
        def build_line_break(ast)
          {
            type: :line_break,
            content: ast[:line_break] || ast['line_break']
          }
        end

        # Build comment line
        def build_comment_line(ast)
          comment_ast = ast[:comment_line] || ast['comment_line'] || ast

          {
            type: :comment_line,
            text: comment_ast[:comment_text] || comment_ast['comment_text'],
            line_break: comment_ast[:line_break] || comment_ast['line_break']
          }
        end

        # Build comment block
        def build_comment_block(ast)
          comment_ast = ast[:comment_block] || ast['comment_block'] || ast

          {
            type: :comment_block,
            text: comment_ast[:comment_text] || comment_ast['comment_text']
          }
        end

        # Build include directive
        def build_include(ast)
          include_ast = ast[:include] || ast['include'] || ast

          {
            type: :include,
            path: include_ast[:path] || include_ast['path'],
            attributes: build_attributes_private(
              include_ast[:attribute_list] || include_ast['attribute_list']
            ),
            line_break: include_ast[:line_break] || include_ast['line_break']
          }
        end

        # Build table element
        def build_table(ast)
          table_ast = ast[:table] || ast['table'] || ast

          {
            type: :table,
            title: table_ast[:title] || table_ast['title'],
            id: table_ast[:id] || table_ast['id'],
            rows: table_ast[:rows] || table_ast['rows'] || [],
            attributes: build_attributes_private(
              table_ast[:attribute_list] || table_ast['attribute_list']
            )
          }
        end

        # Build unparsed text element
        def build_unparsed(ast)
          {
            type: :unparsed,
            text: (ast[:unparsed] || ast['unparsed']).to_s
          }
        end

        # Build tag element
        def build_tag(ast)
          tag_ast = ast[:tag] || ast['tag'] || ast

          {
            type: :tag,
            name: tag_ast[:name] || tag_ast['name'],
            attributes: build_attributes_private(
              tag_ast[:attribute_list] || tag_ast['attribute_list']
            ),
            line_break: tag_ast[:line_break] || tag_ast['line_break'],
            prefix: tag_ast[:prefix] || tag_ast['prefix']
          }
        end

        # Build bibliography entry
        def build_bibliography_entry(ast)
          bib_ast = ast[:bibliography_entry] || ast['bibliography_entry'] || ast

          {
            type: :bibliography_entry,
            anchor_name: bib_ast[:anchor_name] || bib_ast['anchor_name'],
            document_id: bib_ast[:document_id] || bib_ast['document_id'],
            ref_text: bib_ast[:ref_text] || bib_ast['ref_text'],
            line_break: bib_ast[:line_break] || bib_ast['line_break']
          }
        end

        # Build generic element for unknown types
        def build_generic_element(ast)
          {
            type: :unknown,
            ast: ast
          }
        end

        # Build single attribute
        def build_attribute(ast)
          {
            key: ast[:key],
            value: ast[:value],
            line_break: ast[:line_break]
          }
        end
      end
    end
  end
end
