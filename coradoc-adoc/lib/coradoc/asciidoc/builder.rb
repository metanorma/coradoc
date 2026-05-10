# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    class Builder
      autoload :Detection, "#{__dir__}/builder/detection"
      autoload :ListBuilder, "#{__dir__}/builder/list_builder"
      autoload :BlockBuilder, "#{__dir__}/builder/block_builder"
      autoload :TextBuilder, "#{__dir__}/builder/text_builder"
      autoload :ElementBuilder, "#{__dir__}/builder/element_builder"

      include Detection
      include ListBuilder
      include BlockBuilder
      include TextBuilder
      include ElementBuilder

      def self.build(ast)
        new.build_document(ast)
      end

      def build_document(ast)
        return nil unless ast.is_a?(Hash)

        if ast.key?(:document)
          build_document_elements(ast[:document])
        else
          build_document_elements(ast)
        end
      end

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
          build_generic_element(ast)
        end
      end

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

      def build_paragraph(ast)
        para_ast = ast[:paragraph] || ast

        Coradoc::CoreModel::ParagraphBlock.new(
          content: build_paragraph_content(para_ast[:lines]).join("\n"),
          id: para_ast[:id],
          title: para_ast[:title]
        )
      end

      def build_inline(ast)
        format_type = detect_inline_format(ast)
        klass = Coradoc::CoreModel::InlineElement.format_type_class(format_type)

        klass.new(
          constrained: detect_constrained(ast, format_type),
          content: extract_inline_content(ast, format_type),
          nested_elements: build_nested_inlines(ast)
        )
      end

      def build_attributes(attr_ast)
        return [] unless attr_ast

        case attr_ast
        when Hash
          attributes = []

          if attr_ast[:positional]
            Array(attr_ast[:positional]).each do |pos|
              attributes << Coradoc::CoreModel::ElementAttribute.new(
                name: pos.to_s
              )
            end
          end

          if attr_ast[:named]
            Array(attr_ast[:named]).each do |named|
              next unless named.is_a?(Hash)

              attributes << Coradoc::CoreModel::ElementAttribute.new(
                name: named[:key] || named[:named_key],
                value: named[:value] || named[:named_value]
              )
            end
          end

          attributes
        when Array
          attr_ast.map { |attr| build_attribute(attr) }.compact
        else
          []
        end
      end

      def build_document_attributes(ast)
        attrs_ast = ast[:document_attributes] || ast

        Array(attrs_ast).map do |attr|
          Coradoc::CoreModel::ElementAttribute.new(
            key: attr[:key],
            value: attr[:value]
          )
        end
      end

      private

      def build_text(ast)
        Coradoc::CoreModel::InlineElement.new(
          content: extract_text_content(ast)
        )
      end

      def build_paragraph_content(lines)
        return [] unless lines

        Array(lines).map { |line| extract_text_content(line) }
      end

      def build_document_elements(ast)
        elements = []

        elements << build_header(ast) if ast[:header]

        if ast[:sections]
          elements.concat(
            Array(ast[:sections]).map { |s| build_element(s) }.compact
          )
        end

        elements << build_document_attributes(ast) if ast[:document_attributes]

        %i[paragraph block list table].each do |key|
          next unless ast[key]

          Array(ast[key]).each do |item|
            elements << build_element({ key => item })
          end
        end

        group_document_elements(elements)
      end

      def group_document_elements(elements)
        header = elements.find { |e| e.is_a?(CoreModel::HeaderElement) }
        sections = elements.select { |e| e.is_a?(CoreModel::SectionElement) }
        doc_attrs = elements.select { |e| e.is_a?(CoreModel::ElementAttribute) }
        other_content = elements.reject do |e|
          e.is_a?(CoreModel::HeaderElement) ||
            e.is_a?(CoreModel::SectionElement) ||
            e.is_a?(CoreModel::ElementAttribute)
        end

        result = {}
        result[:header] = header if header
        result[:sections] = sections if sections.any?
        result[:content] = other_content if other_content.any?
        result[:document_attributes] = doc_attrs if doc_attrs.any?
        result
      end

      def build_attributes_private(attr_ast)
        build_attributes(attr_ast)
      end
    end
  end
end
