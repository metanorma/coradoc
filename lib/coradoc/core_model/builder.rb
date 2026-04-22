# frozen_string_literal: true

require 'logger'

# Load builder modules
require_relative 'builder/detection'
require_relative 'builder/list_builder'
require_relative 'builder/block_builder'
require_relative 'builder/text_builder'
require_relative 'builder/element_builder'

module Coradoc
  module CoreModel
    # Builds CoreModel objects from generic AST
    #
    # This class provides a clean separation between parsing and model construction,
    # replacing the Parslet::Transform dependency with a dedicated builder that can
    # be independently tested and maintained.
    #
    # The builder uses AST detection logic to determine the appropriate CoreModel
    # type to create, handling all current AST structures with graceful fallbacks.
    #
    # The builder is organized into modules for maintainability:
    # - Detection: Element type detection and extraction methods
    # - ListBuilder: List building methods
    # - BlockBuilder: Block building methods
    # - TextBuilder: Text and inline building methods
    # - ElementBuilder: Miscellaneous element building methods
    #
    # @example Building a document from AST
    #   ast = {
    #     header: { title: "Document Title" },
    #     sections: [{ section: { title: "Introduction" } }],
    #     document_attributes: [{ key: "author", value: "John Doe" }]
    #   }
    #   document = CoreModel::Builder.build(ast)
    #
    # @example Building individual blocks
    #   block_ast = {
    #     block: {
    #       delimiter: "****",
    #       lines: ["This is a note"],
    #       attribute_list: { positional: ["NOTE"] }
    #     }
    #   }
    #   block = CoreModel::Builder.new.build_block(block_ast)
    class Builder
      include Detection
      include ListBuilder
      include BlockBuilder
      include TextBuilder
      include ElementBuilder

      # Build document from AST
      #
      # @param ast [Hash] the AST representation of a document
      # @return [Hash] document structure for compatibility with existing code
      def self.build(ast)
        new.build_document(ast)
      end

      # Initialize a new builder instance
      def initialize
        # No logger setup needed - use Coradoc::Logger class methods
      end

      # Build document structure from AST
      #
      # @param ast [Hash] the document AST
      # @return [Hash] document structure with header, sections, and attributes
      def build_document(ast)
        case ast
        when Hash
          if ast.key?(:document)
            build_document_elements(ast[:document])
          else
            build_document_elements(ast)
          end
        when Array
          elements = ast.map { |element| build_element(element) }.compact
          group_document_elements(elements)
        else
          Coradoc::Logger.warn("Unexpected AST format: #{ast.class}")
          { sections: [] }
        end
      end

      # Build any element from AST based on type detection
      #
      # @param ast [Hash] the element AST
      # @return [Object] the built element
      def build_element(ast)
        return nil unless ast.is_a?(Hash)

        case detect_element_type(ast)
        when :header
          build_header(ast)
        when :section
          build_section(ast)
        when :block
          build_block(ast)
        when :list
          build_list(ast)
        when :paragraph
          build_paragraph(ast)
        when :inline
          build_inline(ast)
        when :text
          build_text(ast)
        when :attribute
          build_attribute(ast)
        when :document_attributes
          build_document_attributes(ast)
        when :line_break
          build_line_break(ast)
        when :comment_line
          build_comment_line(ast)
        when :comment_block
          build_comment_block(ast)
        when :include
          build_include(ast)
        when :table
          build_table(ast)
        when :unparsed
          build_unparsed(ast)
        when :tag
          build_tag(ast)
        when :bibliography_entry
          build_bibliography_entry(ast)
        else
          Coradoc::Logger.info("Unknown element type: #{ast.keys}")
          build_generic_element(ast)
        end
      rescue StandardError => e
        Coradoc::Logger.error("Error building element: #{e.message}")
        Coradoc::Logger.info("AST: #{ast.inspect[0..200]}")
        nil
      end

      # Build a block element with type detection
      def build_block(ast)
        block_ast = ast[:block] || ast

        case detect_block_type(block_ast)
        when :annotation
          build_annotation_block(block_ast)
        when :list
          build_list_block(block_ast)
        else
          build_generic_block(block_ast)
        end
      end

      # Build list element from various AST formats
      def build_list(ast)
        if ast[:unordered]
          build_unordered_list(ast)
        elsif ast[:ordered]
          build_ordered_list(ast)
        elsif ast[:definition_list]
          build_definition_list(ast)
        else
          build_list_block(ast)
        end
      end

      # Build individual list item
      def build_list_item(ast)
        item_ast = ast[:list_item] || ast

        ListItem.new(
          marker: item_ast[:marker]&.to_s,
          content: extract_item_content(item_ast),
          nested_list: build_nested_list(item_ast[:nested]),
          children: build_item_children(item_ast[:attached])
        )
      end

      # Build paragraph
      def build_paragraph(ast)
        para_ast = ast[:paragraph] || ast

        {
          type: :paragraph,
          content: build_paragraph_content(para_ast[:lines]),
          id: para_ast[:id],
          title: para_ast[:title],
          attribute_list: para_ast[:attribute_list]
        }
      end

      # Build inline element
      def build_inline(ast)
        format_type = detect_inline_format(ast)

        InlineElement.new(
          format_type: format_type,
          constrained: detect_constrained(ast, format_type),
          content: extract_inline_content(ast, format_type),
          nested_elements: build_nested_inlines(ast)
        )
      end

      # Build attributes from attribute list AST (public version)
      def build_attributes(attr_ast)
        return [] unless attr_ast

        case attr_ast
        when Hash
          attributes = []

          if attr_ast[:positional]
            Array(attr_ast[:positional]).each do |pos|
              attributes << { positional: pos.to_s }
            end
          end

          if attr_ast[:named]
            Array(attr_ast[:named]).each do |named|
              next unless named.is_a?(Hash)

              attributes << {
                key: named[:key] || named[:named_key],
                value: named[:value] || named[:named_value]
              }
            end
          end

          attributes
        when Array
          attr_ast.map { |attr| build_attribute(attr) }.compact
        else
          []
        end
      end

      # Build document attributes
      def build_document_attributes(ast)
        attrs_ast = ast[:document_attributes] || ast

        {
          type: :document_attributes,
          attributes: Array(attrs_ast).map do |attr|
            {
              key: attr[:key],
              value: attr[:value],
              line_break: attr[:line_break]
            }
          end
        }
      end

      private

      # Build document elements from AST hash
      def build_document_elements(ast)
        elements = []

        # Extract header if present
        elements << build_header(ast) if ast[:header]

        # Extract sections
        if ast[:sections]
          elements.concat(
            Array(ast[:sections]).map { |s| build_element(s) }.compact
          )
        end

        # Extract document attributes
        elements << build_document_attributes(ast) if ast[:document_attributes]

        # Extract other content
        %i[paragraph block list table].each do |key|
          next unless ast[key]

          Array(ast[key]).each do |item|
            elements << build_element({ key => item })
          end
        end

        group_document_elements(elements)
      end

      # Group elements into document structure
      def group_document_elements(elements)
        header = elements.find { |e| e[:type] == :header }
        sections = elements.select { |e| e[:type] == :section }
        doc_attrs = elements.find { |e| e[:type] == :document_attributes }
        other_content = elements.reject do |e|
          %i[header section document_attributes].include?(e[:type])
        end

        result = {}

        result[:header] = header if header

        result[:sections] = sections if sections.any?

        result[:content] = other_content if other_content.any?

        result[:document_attributes] = doc_attrs[:attributes] if doc_attrs

        result
      end

      # Build attributes from attribute list AST (private version)
      def build_attributes_private(attr_ast)
        build_attributes(attr_ast)
      end
    end
  end
end
