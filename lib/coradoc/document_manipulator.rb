# frozen_string_literal: true

module Coradoc
  # Document Manipulator for chainable document operations
  #
  # Provides a fluent API for manipulating CoreModel documents:
  # - Query and filter elements
  # - Transform content
  # - Add/modify/remove elements
  # - Serialize to various formats
  #
  # @example Basic usage
  #   doc = Coradoc.parse(text, format: :asciidoc)
  #   html = Coradoc::DocumentManipulator.new(doc)
  #     .select_sections(level: 1..2)
  #     .transform_text(&:upcase)
  #     .add_toc
  #     .to_html
  #
  # @example Chaining operations
  #   manipulator = Coradoc::DocumentManipulator.new(document)
  #     .remove_elements(:comment_line)
  #     .transform_headings { |h| h.upcase }
  #     .add_metadata("processed_at" => Time.now.iso8601)
  #
  class DocumentManipulator
    # @return [Coradoc::CoreModel::StructuralElement] the wrapped document
    attr_reader :document

    # Create a new document manipulator
    #
    # @param document [Coradoc::CoreModel::Base] the document to manipulate
    # @raise [ArgumentError] if document is not a CoreModel::Base
    def initialize(document)
      unless document.is_a?(Coradoc::CoreModel::Base)
        raise ArgumentError,
              "Expected CoreModel::Base, got #{document.class}"
      end

      @document = document
    end

    # Query elements using CSS-like selectors
    #
    # @param selector [String] CSS-like selector
    # @return [Array<Coradoc::CoreModel::Base>] matching elements
    def query(selector)
      results = []
      query_elements(@document, selector, results)
      results
    end

    # Select sections by criteria
    #
    # @param level [Range, Integer, nil] section level filter
    # @param title [String, Regexp, nil] title filter
    # @return [DocumentManipulator] self for chaining
    def select_sections(level: nil, title: nil)
      # This is a filter operation that returns a new manipulator
      # with the filtered document
      filtered = filter_sections(@document, level: level, title: title)
      DocumentManipulator.new(filtered)
    end

    # Transform all text content
    #
    # @yield [String] text content to transform
    # @return [DocumentManipulator] self for chaining
    def transform_text(&block)
      return self unless block_given?

      transform_text_in_element(@document, &block)
      self
    end

    # Transform all headings/titles
    #
    # @yield [String] heading text to transform
    # @return [DocumentManipulator] self for chaining
    def transform_headings(&block)
      return self unless block_given?

      transform_headings_in_element(@document, &block)
      self
    end

    # Add table of contents
    #
    # @param options [Hash] TOC options
    # @option options [Integer] :levels number of levels to include
    # @option options [Symbol] :position (:top, :bottom) where to place TOC
    # @return [DocumentManipulator] self for chaining
    def add_toc(levels: 3, position: :top)
      toc = generate_toc(levels: levels)

      case position
      when :top
        insert_toc_at_top(toc)
      when :bottom
        insert_toc_at_bottom(toc)
      end

      self
    end

    # Remove elements by type
    #
    # @param element_type [Symbol] type of elements to remove
    # @return [DocumentManipulator] self for chaining
    def remove_elements(element_type)
      remove_elements_by_type(@document, element_type)
      self
    end

    # Add metadata to document
    #
    # @param metadata [Hash] metadata key-value pairs
    # @return [DocumentManipulator] self for chaining
    def add_metadata(metadata)
      metadata.each do |key, value|
        @document.set_metadata(key.to_s, value.to_s)
      end
      self
    end

    # Set document title
    #
    # @param title [String] new title
    # @return [DocumentManipulator] self for chaining
    def set_title(title)
      @document.title = title
      self
    end

    # Set document ID
    #
    # @param id [String] new ID
    # @return [DocumentManipulator] self for chaining
    def set_id(id)
      @document.id = id
      self
    end

    # Serialize to HTML
    #
    # @param options [Hash] serialization options
    # @return [String] HTML output
    def to_html(**options)
      Coradoc.serialize(@document, to: :html, **options)
    end

    # Serialize to Markdown
    #
    # @param options [Hash] serialization options
    # @return [String] Markdown output
    def to_markdown(**options)
      Coradoc.serialize(@document, to: :markdown, **options)
    end

    # Serialize to AsciiDoc
    #
    # @param options [Hash] serialization options
    # @return [String] AsciiDoc output
    def to_asciidoc(**options)
      Coradoc.serialize(@document, to: :asciidoc, **options)
    end

    # Serialize to specified format
    #
    # @param format [Symbol] target format (:html, :markdown, :asciidoc)
    # @param options [Hash] serialization options
    # @return [String] serialized output
    def to(format, **options)
      Coradoc.serialize(@document, to: format, **options)
    end

    # Get the underlying CoreModel document
    #
    # @return [Coradoc::CoreModel::Base] the document
    def to_core
      @document
    end

    # Clone this manipulator with a copy of the document
    #
    # @return [DocumentManipulator] new manipulator with cloned document
    def clone
      # Deep clone the document
      cloned_doc = deep_clone(@document)
      DocumentManipulator.new(cloned_doc)
    end

    private

    # Filter sections by criteria
    def filter_sections(element, level: nil, title: nil)
      return element unless element.respond_to?(:children)

      if element.is_a?(Coradoc::CoreModel::StructuralElement) && (element.element_type == 'section')
        # Check if this section matches criteria
        matches = true

        if level
          element_level = element.level || 1
          case level
          when Range
            matches = false unless level.include?(element_level)
          when Integer
            matches = false unless element_level == level
          end
        end

        if title && matches
          element_title = element.title || ''
          case title
          when String
            matches = element_title.include?(title)
          when Regexp
            matches = element_title =~ title
          end
        end

        return nil unless matches
      end

      # Recursively filter children
      if element.respond_to?(:children) && element.children
        filtered_children = element.children.map do |child|
          filter_sections(child, level: level, title: title)
        end.compact

        element.children = filtered_children if element.respond_to?(:children=)
      end

      element
    end

    # Transform text content in an element
    def transform_text_in_element(element, &block)
      case element
      when Coradoc::CoreModel::InlineElement
        element.content = yield(element.content) if element.content.is_a?(String)
      when Coradoc::CoreModel::Block
        element.content = yield(element.content) if element.content.is_a?(String)
      end

      # Recurse into children
      return unless element.respond_to?(:children) && element.children

      element.children.each do |child|
        transform_text_in_element(child, &block)
      end
    end

    # Transform headings in an element
    def transform_headings_in_element(element, &block)
      if element.is_a?(Coradoc::CoreModel::StructuralElement) && element.title.is_a?(String)
        element.title = yield(element.title)
      end

      # Recurse into children
      return unless element.respond_to?(:children) && element.children

      element.children.each do |child|
        transform_headings_in_element(child, &block)
      end
    end

    # Generate table of contents
    def generate_toc(levels: 3)
      sections = collect_sections(@document, max_level: levels)
      Coradoc::CoreModel::TocGenerator.generate(sections)
    end

    # Collect sections up to max_level
    def collect_sections(element, max_level: 3, current_level: 1)
      sections = []

      return sections unless element.respond_to?(:children)

      element.children.each do |child|
        next unless child.is_a?(Coradoc::CoreModel::StructuralElement) &&
                    child.element_type == 'section' && (current_level <= max_level)

        sections << {
          id: child.id,
          title: child.title,
          level: child.level || current_level,
          children: collect_sections(child, max_level: max_level,
                                            current_level: current_level + 1)
        }
      end

      sections
    end

    # Insert TOC at top of document
    def insert_toc_at_top(toc)
      return unless @document.respond_to?(:children=) && @document.respond_to?(:children)

      toc_element = Coradoc::CoreModel::Block.new(
        element_type: 'toc',
        content: toc
      )
      @document.children = [toc_element] + @document.children
    end

    # Insert TOC at bottom of document
    def insert_toc_at_bottom(toc)
      return unless @document.respond_to?(:children=) && @document.respond_to?(:children)

      toc_element = Coradoc::CoreModel::Block.new(
        element_type: 'toc',
        content: toc
      )
      @document.children = @document.children + [toc_element]
    end

    # Remove elements by type
    def remove_elements_by_type(element, element_type)
      return unless element.respond_to?(:children) && element.children

      element.children.reject! do |child|
        case element_type
        when :comment_line, :comment_block
          child.is_a?(Coradoc::CoreModel::Block) &&
            child.element_type&.to_s&.include?('comment')
        when :line_break
          child.is_a?(Coradoc::CoreModel::Block) &&
            child.element_type == 'line_break'
        else
          child.is_a?(Coradoc::CoreModel::Block) &&
            child.element_type&.to_s == element_type.to_s
        end
      end

      # Recurse into remaining children
      element.children.each do |child|
        remove_elements_by_type(child, element_type)
      end
    end

    # Deep clone an element
    def deep_clone(element)
      case element
      when Coradoc::CoreModel::Base
        # Use lutaml-model's duplication
        cloned = element.class.new
        element.class.attributes.each_key do |name|
          value = element.send(name)
          cloned.send("#{name}=", deep_clone(value))
        end
        cloned
      when Array
        element.map { |item| deep_clone(item) }
      when Hash
        element.transform_values { |v| deep_clone(v) }
      else
        begin
          element.dup
        rescue StandardError
          element
        end
      end
    end

    # Query elements matching a selector
    def query_elements(element, selector, results)
      # Simple selector matching by element_type
      if element.respond_to?(:element_type)
        type_match = selector.gsub(/[#.\[].*/, '').downcase
        results << element if type_match.empty? || element.element_type&.downcase == type_match
      end

      # Recurse into children
      return unless element.respond_to?(:children) && element.children

      element.children.each do |child|
        query_elements(child, selector, results)
      end
    end
  end
end
