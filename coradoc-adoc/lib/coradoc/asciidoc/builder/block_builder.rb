# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    class Builder
      module BlockBuilder
        def build_annotation_block(ast)
          Coradoc::CoreModel::AnnotationBlock.new(
            annotation_type: extract_annotation_type(ast),
            annotation_label: extract_annotation_label(ast),
            content: extract_block_content(ast),
            lines: extract_block_lines(ast),
            title: ast[:title],
            id: ast[:id],
            attributes: build_attributes_private(ast[:attribute_list])
          )
        end

        def build_generic_block(ast)
          Coradoc::CoreModel::Block.new(
            delimiter_type: ast[:delimiter]&.to_s,
            content: extract_block_content(ast),
            lines: extract_block_lines(ast),
            title: ast[:title],
            id: ast[:id],
            attributes: build_attributes_private(ast[:attribute_list])
          )
        end

        def extract_block_content(ast)
          return ast[:content] if ast[:content]

          if ast[:lines]
            lines = Array(ast[:lines])
            return lines.map { |line| extract_text_content(line) }.join("\n")
          end

          ''
        end

        def extract_block_lines(ast)
          return [] unless ast[:lines]

          Array(ast[:lines]).map { |line| extract_text_content(line) }
        end
      end
    end
  end
end
