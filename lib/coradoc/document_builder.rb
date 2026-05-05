# frozen_string_literal: true

module Coradoc
  class DocumentBuilder
    attr_reader :document

    def self.build(&block)
      builder = new
      builder.instance_eval(&block) if block_given?
      builder
    end

    def initialize
      @document = CoreModel::StructuralElement.new(
        element_type: 'document',
        children: []
      )
      @current_context = @document
      @context_stack = []
    end

    def title(text)
      @document.title = text
      self
    end

    def section(title_text, level: 1, &block)
      new_section = CoreModel::StructuralElement.new(
        element_type: 'section',
        level: level,
        title: title_text,
        children: []
      )

      @current_context.children << new_section

      if block_given?
        push_context(new_section)
        instance_eval(&block)
        pop_context
      end

      self
    end

    def paragraph(text)
      @current_context.children << CoreModel::Block.new(
        element_type: 'paragraph',
        content: text
      )
      self
    end

    def code(code_text, language: nil)
      @current_context.children << CoreModel::Block.new(
        element_type: 'block',
        delimiter_type: '----',
        content: code_text,
        language: language
      )
      self
    end

    def blockquote(text, attribution: nil)
      block = CoreModel::Block.new(
        element_type: 'block',
        delimiter_type: '____',
        content: text
      )
      block.set_metadata('attribution', attribution) if attribution
      @current_context.children << block
      self
    end

    def list(type = :unordered, &block)
      list_items = []
      list_type = type

      wrapper = Object.new
      wrapper.define_singleton_method(:item) do |text|
        marker = list_type == :ordered ? '1.' : '*'
        list_items << CoreModel::ListItem.new(content: text, marker: marker)
        wrapper
      end

      wrapper.instance_eval(&block) if block_given?

      @current_context.children << CoreModel::ListBlock.new(
        marker_type: type.to_s,
        items: list_items
      )
      self
    end

    alias ordered_list list
    alias unordered_list list

    def bulleted_list(&block)
      list(:unordered, &block)
    end

    def numbered_list(&block)
      list(:ordered, &block)
    end

    def image(src, alt: '', title: nil)
      img = CoreModel::Image.new(src: src, alt: alt)
      img.title = title if title
      @current_context.children << img
      self
    end

    def table(headers = [], rows = [])
      table_rows = []

      if headers.any?
        header_cells = headers.map { |h| CoreModel::TableCell.new(content: h, header: true) }
        table_rows << CoreModel::TableRow.new(cells: header_cells)
      end

      rows.each do |row|
        cells = row.map { |c| CoreModel::TableCell.new(content: c.to_s) }
        table_rows << CoreModel::TableRow.new(cells: cells)
      end

      @current_context.children << CoreModel::Table.new(rows: table_rows)
      self
    end

    def hr
      @current_context.children << CoreModel::Block.new(
        element_type: 'horizontal_rule'
      )
      self
    end

    def text(text_content)
      @current_context.children << CoreModel::Block.new(
        element_type: 'text',
        content: text_content
      )
      self
    end

    def admonition(type, text)
      @current_context.children << CoreModel::AnnotationBlock.new(
        annotation_type: type.to_s,
        content: text
      )
      self
    end

    %i[note warning tip important caution].each do |admonition_type|
      define_method(admonition_type) do |text|
        admonition(admonition_type, text)
      end
    end

    def to_core
      @document
    end

    def to(format, **options)
      Coradoc.serialize(@document, to: format, **options)
    end

    def to_html(**options)
      to(:html, **options)
    end

    def to_markdown(**options)
      to(:markdown, **options)
    end

    def to_asciidoc(**options)
      to(:asciidoc, **options)
    end

    private

    def push_context(new_context)
      @context_stack << @current_context
      @current_context = new_context
    end

    def pop_context
      @current_context = @context_stack.pop
    end
  end

  def self.build(&block)
    DocumentBuilder.build(&block)
  end
end
