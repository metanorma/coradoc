# frozen_string_literal: true

module Coradoc
  module CoreModel
    class Builder
      # Block building module for Builder
      #
      # Contains methods for building block elements from AST structures.
      #
      # @api private
      module BlockBuilder
        # Build annotation block
        def build_annotation_block(ast)
          annotation_type = extract_annotation_type(ast)

          AnnotationBlock.new(
            annotation_type: annotation_type,
            annotation_label: extract_annotation_label(ast),
            delimiter_type: ast[:delimiter]&.to_s,
            delimiter_length: ast[:delimiter]&.to_s&.length || 4,
            content: extract_block_content(ast),
            lines: extract_block_lines(ast),
            title: ast[:title],
            id: ast[:id],
            attributes: build_attributes_private(ast[:attribute_list])
          )
        end

        # Build generic block
        def build_generic_block(ast)
          Block.new(
            delimiter_type: ast[:delimiter]&.to_s,
            delimiter_length: ast[:delimiter]&.to_s&.length || 4,
            content: extract_block_content(ast),
            lines: extract_block_lines(ast),
            title: ast[:title],
            id: ast[:id],
            attributes: build_attributes_private(ast[:attribute_list])
          )
        end

        # Extract block content from various AST formats
        def extract_block_content(ast)
          return ast[:content] if ast[:content]

          if ast[:lines]
            lines = Array(ast[:lines])
            return lines.map { |line| extract_text_content(line) }.join("\n")
          end

          ''
        end

        # Extract block lines
        def extract_block_lines(ast)
          return [] unless ast[:lines]

          Array(ast[:lines]).map { |line| extract_text_content(line) }
        end
      end
    end
  end
end
