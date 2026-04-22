# frozen_string_literal: true

module Coradoc
  # Fluent Document Builder API
  #
  # Provides a convenient way to create CoreModel documents programmatically
  # using a fluent interface pattern.
  #
  # @example Create a simple document
  #   doc = Coradoc::DocumentBuilder.build do
  #     title "My Document"
  #     section "Introduction" do
  #       paragraph "This is the introduction."
  #     end
  #   end
  #
  # @example Create a document with lists and code
  #   doc = Coradoc::DocumentBuilder.build do
  #     title "API Reference"
  #     section "Getting Started" do
  #       paragraph "Follow these steps:"
  #       list :ordered do
  #         item "Install the gem"
  #         item "Require the library"
  #         item "Start coding"
  #       end
  #     end
  #     section "Examples" do
  #       code "puts 'Hello, World!'", language: "ruby"
  #     end
  #   end
  #
  # @example Convert the built document
  #   html = Coradoc.serialize(doc.to_core, to: :html)
  #
  class DocumentBuilder
    attr_reader :document

    # Build a document using the fluent API
    #
    # @yield Block containing document building commands
    # @return [DocumentBuilder] The builder instance
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

    # Set the document title
    #
    # @param text [String] The document title
    # @return [DocumentBuilder] self for chaining
    def title(text)
      @document.title = text
      self
    end

    # Add a section
    #
    # @param title_text [String] The section title
    # @param level [Integer] The section level (1-6)
    # @yield Block containing section content
    # @return [DocumentBuilder] self for chaining
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

    # Add a paragraph
    #
    # @param text [String] The paragraph content
    # @return [DocumentBuilder] self for chaining
    def paragraph(text)
      @current_context.children << CoreModel::Block.new(
        element_type: 'paragraph',
        content: text
      )
      self
    end

    # Add a code block
    #
    # @param code [String] The code content
    # @param language [String, nil] The programming language
    # @return [DocumentBuilder] self for chaining
    def code(code_text, language: nil)
      @current_context.children << CoreModel::Block.new(
        element_type: 'block',
        delimiter_type: '----',
        content: code_text,
        language: language
      )
      self
    end

    # Add a blockquote
    #
    # @param text [String] The quote content
    # @param attribution [String, nil] Optional attribution
    # @return [DocumentBuilder] self for chaining
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

    # Add a list
    #
    # @param type [Symbol] List type (:ordered, :unordered, :definition)
    # @yield Block containing list items
    # @return [DocumentBuilder] self for chaining
    def list(type = :unordered, &block)
      @list_items = []
      @list_type = type

      instance_eval(&block) if block_given?

      @current_context.children << CoreModel::ListBlock.new(
        marker_type: type.to_s,
        items: @list_items
      )

      @list_items = nil
      @list_type = nil
      self
    end

    alias ordered_list list
    alias unordered_list list

    # Add a bulleted list (unordered)
    #
    # @yield Block containing list items
    # @return [DocumentBuilder] self for chaining
    def bulleted_list(&block)
      list(:unordered, &block)
    end

    # Add a numbered list (ordered)
    #
    # @yield Block containing list items
    # @return [DocumentBuilder] self for chaining
    def numbered_list(&block)
      list(:ordered, &block)
    end

    # Add a list item
    #
    # @param text [String] The item content
    # @return [DocumentBuilder] self for chaining
    def item(text)
      return self unless @list_items

      marker = @list_type == :ordered ? '1.' : '*'
      @list_items << CoreModel::ListItem.new(content: text, marker: marker)
      self
    end

    # Add an image
    #
    # @param src [String] The image source URL or path
    # @param alt [String] Alt text
    # @param title [String, nil] Optional title
    # @return [DocumentBuilder] self for chaining
    def image(src, alt: '', title: nil)
      img = CoreModel::Image.new(src: src, alt: alt)
      img.title = title if title
      @current_context.children << img
      self
    end

    # Add a table
    #
    # @param headers [Array<String>] Table headers
    # @param rows [Array<Array<String>>] Table rows
    # @return [DocumentBuilder] self for chaining
    def table(headers = [], rows = [])
      table_rows = []

      # Add header row
      if headers.any?
        header_cells = headers.map { |h| CoreModel::TableCell.new(content: h, header: true) }
        table_rows << CoreModel::TableRow.new(cells: header_cells)
      end

      # Add data rows
      rows.each do |row|
        cells = row.map { |c| CoreModel::TableCell.new(content: c.to_s) }
        table_rows << CoreModel::TableRow.new(cells: cells)
      end

      @current_context.children << CoreModel::Table.new(rows: table_rows)
      self
    end

    # Add a horizontal rule
    #
    # @return [DocumentBuilder] self for chaining
    def hr
      @current_context.children << CoreModel::Block.new(
        element_type: 'horizontal_rule'
      )
      self
    end

    # Add raw text (HTML-safe)
    #
    # @param text [String] The text content
    # @return [DocumentBuilder] self for chaining
    def text(text_content)
      @current_context.children << CoreModel::Block.new(
        element_type: 'text',
        content: text_content
      )
      self
    end

    # Add an admonition (note, warning, tip, etc.)
    #
    # @param type [Symbol] Admonition type (:note, :warning, :tip, :important, :caution)
    # @param text [String] The admonition content
    # @return [DocumentBuilder] self for chaining
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

    # Convert to CoreModel document
    #
    # @return [CoreModel::StructuralElement] The CoreModel document
    def to_core
      @document
    end

    # Convert to specified format
    #
    # @param format [Symbol] Target format (:html, :markdown, :asciidoc)
    # @param options [Hash] Additional options
    # @return [String] The serialized document
    def to(format, **options)
      Coradoc.serialize(@document, to: format, **options)
    end

    # Convert to HTML
    #
    # @param options [Hash] Additional options
    # @return [String] HTML output
    def to_html(**options)
      to(:html, **options)
    end

    # Convert to Markdown
    #
    # @param options [Hash] Additional options
    # @return [String] Markdown output
    def to_markdown(**options)
      to(:markdown, **options)
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

  # Convenience method to build a document
  #
  # @yield Block containing document building commands
  # @return [DocumentBuilder] The builder instance
  def self.build(&block)
    DocumentBuilder.build(&block)
  end
end
