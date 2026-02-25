# frozen_string_literal: true

module Coradoc
  module CoreModel
    class Builder
      # Text building module for Builder
      #
      # Contains methods for building text and inline elements from AST structures.
      #
      # @api private
      module TextBuilder
        # Build paragraph content from lines
        def build_paragraph_content(lines_ast)
          return [] unless lines_ast

          Array(lines_ast).map { |line| build_text_element(line) }.compact
        end

        # Build text element
        def build_text_element(ast)
          return { type: :text, content: ast } if ast.is_a?(String)

          text_ast = ast[:text] ? ast : { text: ast }

          {
            type: :text,
            content: extract_text_content(text_ast),
            line_break: text_ast[:line_break],
            id: text_ast[:id]
          }
        end

        # Build text from AST
        def build_text(ast)
          build_text_element(ast)
        end

        # Extract text content from various formats
        def extract_text_content(ast)
          case ast
          when String
            ast
          when Hash
            if ast[:text]
              case ast[:text]
              when String
                ast[:text]
              when Array
                ast[:text].map { |t| extract_text_content(t) }.join
              else
                ast[:text].to_s
              end
            elsif ast[:content]
              ast[:content].to_s
            else
              ast.to_s
            end
          else
            ast.to_s
          end
        end

        # Extract inline content
        def extract_inline_content(ast, format_type)
          content_key = format_type.to_sym
          content = ast[content_key] ||
                    ast["#{format_type}_constrained".to_sym] ||
                    ast["#{format_type}_unconstrained".to_sym]

          extract_text_content(content)
        end

        # Build nested inline elements
        def build_nested_inlines(ast)
          nested = []

          ast.each_value do |value|
            next unless value.is_a?(Array)

            value.each do |item|
              nested << build_inline(item) if item.is_a?(Hash) && has_inline_structure?(item)
            end
          end

          nested
        end
      end
    end
  end
end
