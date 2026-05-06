# frozen_string_literal: true

module Coradoc
  class DocumentManipulator
    attr_reader :document

    def initialize(document)
      unless document.is_a?(Coradoc::CoreModel::Base)
        raise ArgumentError,
              "Expected CoreModel::Base, got #{document.class}"
      end

      @document = document
    end

    def query(selector)
      Coradoc::Query.query(@document, selector).to_a
    end

    def select_sections(level: nil, title: nil)
      filtered = filter_sections(@document, level: level, title: title)
      DocumentManipulator.new(filtered)
    end

    def transform_text
      return self unless block_given?

      Visitor::Transformer.new do |element|
        case element
        when CoreModel::InlineElement
          element.content = yield(element.content) if element.content.is_a?(String)
        when CoreModel::Block
          element.content = yield(element.content) if element.content.is_a?(String)
        end
      end.visit(@document)
      self
    end

    def transform_headings
      return self unless block_given?

      Visitor::Transformer.new do |element|
        element.title = yield(element.title) if element.is_a?(CoreModel::StructuralElement) && element.title.is_a?(String)
      end.visit(@document)
      self
    end

    def add_toc(levels: 3, position: :top)
      sections = collect_sections(@document, max_level: levels)
      toc = CoreModel::TocGenerator.generate(sections)

      toc_element = CoreModel::Block.new(element_type: 'toc', content: toc)
      case position
      when :top
        @document.children = [toc_element] + @document.children
      when :bottom
        @document.children = @document.children + [toc_element]
      end

      self
    end

    def remove_elements(element_type)
      Visitor::Transformer.new do |element|
        next unless element.is_a?(CoreModel::StructuralElement) && element.children

        element.children.reject! do |child|
          match_element_type?(child, element_type)
        end
      end.visit(@document)
      self
    end

    def add_metadata(metadata)
      metadata.each do |key, value|
        @document.set_metadata(key.to_s, value.to_s)
      end
      self
    end

    def set_title(title)
      @document.title = title
      self
    end

    def set_id(id)
      @document.id = id
      self
    end

    def to_html(**options)
      Coradoc.serialize(@document, to: :html, **options)
    end

    def to_markdown(**options)
      Coradoc.serialize(@document, to: :markdown, **options)
    end

    def to_asciidoc(**options)
      Coradoc.serialize(@document, to: :asciidoc, **options)
    end

    def to(format, **options)
      Coradoc.serialize(@document, to: format, **options)
    end

    def to_core
      @document
    end

    def clone
      DocumentManipulator.new(deep_clone(@document))
    end

    private

    def match_element_type?(child, element_type)
      return false unless child.is_a?(CoreModel::Block)

      case element_type
      when :comment_line, :comment_block
        child.element_type&.to_s&.include?('comment')
      else
        child.element_type&.to_s == element_type.to_s
      end
    end

    def filter_sections(element, level: nil, title: nil)
      if element.is_a?(CoreModel::StructuralElement) && element.children
        element.children = element.children
                                  .map { |child| filter_sections(child, level: level, title: title) }
                                  .compact
      end

      return nil if element.is_a?(CoreModel::StructuralElement) && element.section? && !element.document? && !section_matches?(element, level: level, title: title)

      element
    end

    def section_matches?(section, level: nil, title: nil)
      if level
        element_level = section.heading_level
        case level
        when Range then return false unless level.include?(element_level)
        when Integer then return false unless element_level == level
        end
      end

      if title
        element_title = section.title || ''
        case title
        when String then return false unless element_title.include?(title)
        when Regexp then return false unless element_title&.match?(title)
        end
      end

      true
    end

    def collect_sections(element, max_level: 3, current_level: 1)
      sections = []
      return sections unless element.is_a?(CoreModel::StructuralElement)

      element.children.each do |child|
        next unless child.is_a?(CoreModel::StructuralElement) &&
                    child.section? && (current_level <= max_level)

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

    def deep_clone(element)
      case element
      when CoreModel::Base
        cloned = element.class.new
        element.class.attributes.each_key do |name|
          cloned.public_send("#{name}=", deep_clone(element.public_send(name)))
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
  end
end
