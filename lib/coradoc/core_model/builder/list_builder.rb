# frozen_string_literal: true

module Coradoc
  module CoreModel
    class Builder
      # List building module for Builder
      #
      # Contains methods for building list elements from AST structures.
      #
      # @api private
      module ListBuilder
        # Build list block
        def build_list_block(ast)
          ListBlock.new(
            marker_type: detect_marker_type(ast),
            marker_level: detect_marker_level(ast),
            items: build_list_items(ast[:items] || ast[:list_items]),
            title: ast[:title],
            id: ast[:id],
            attributes: build_attributes_private(ast[:attribute_list])
          )
        end

        # Build unordered list
        def build_unordered_list(ast)
          items = Array(ast[:unordered]).map { |item| build_list_item(item) }

          ListBlock.new(
            marker_type: 'asterisk',
            marker_level: 1,
            items: items,
            attributes: build_attributes_private(ast[:attribute_list])
          )
        end

        # Build ordered list
        def build_ordered_list(ast)
          items = Array(ast[:ordered]).map { |item| build_list_item(item) }

          ListBlock.new(
            marker_type: 'numbered',
            marker_level: 1,
            items: items,
            attributes: build_attributes_private(ast[:attribute_list])
          )
        end

        # Build definition list
        def build_definition_list(ast)
          items = Array(ast[:definition_list]).map do |item|
            build_definition_item(item)
          end

          ListBlock.new(
            marker_type: 'definition',
            marker_level: 1,
            items: items,
            attributes: build_attributes_private(ast[:attribute_list])
          )
        end

        # Build list items
        def build_list_items(items_ast)
          return [] unless items_ast

          Array(items_ast).map { |item| build_list_item(item) }
        end

        # Build definition list item
        def build_definition_item(ast)
          item_ast = ast[:definition_list_item] || ast

          ListItem.new(
            marker: '::',
            content: build_definition_content(item_ast),
            children: []
          )
        end

        # Build definition content from terms and definition
        def build_definition_content(ast)
          terms = Array(ast[:terms]).join(', ')
          definition = ast[:definition] || ast[:contents]

          "#{terms}: #{definition}"
        end

        # Build nested list
        def build_nested_list(nested_ast)
          return nil unless nested_ast

          if nested_ast.is_a?(Array)
            ListBlock.new(
              marker_type: 'asterisk',
              marker_level: 2,
              items: nested_ast.map { |item| build_list_item(item) }
            )
          else
            build_element(nested_ast)
          end
        end

        # Build item children (attached blocks)
        def build_item_children(attached_ast)
          return [] unless attached_ast

          Array(attached_ast).map { |child| build_element(child) }.compact
        end

        # Extract item content from various formats
        def extract_item_content(ast)
          if ast[:text]
            case ast[:text]
            when String
              ast[:text]
            when Array
              ast[:text].map(&:to_s).join
            else
              ast[:text].to_s
            end
          elsif ast[:content]
            ast[:content].to_s
          else
            ''
          end
        end
      end
    end
  end
end
