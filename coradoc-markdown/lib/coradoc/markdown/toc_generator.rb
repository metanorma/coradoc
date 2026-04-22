# frozen_string_literal: true

require_relative 'model/base'
require_relative 'model/heading'
require_relative 'model/document'

module Coradoc
  module Markdown
    # Table of Contents Generator
    #
    # Generates a table of contents from document headings.
    # Supports Kramdown-style TOC with options for levels, depth, etc.
    #
    # @example Basic usage
    #   doc = Coradoc::Markdown.parse(markdown_text)
    #   toc = Coradoc::Markdown::TocGenerator.generate(doc)
    #   puts toc.to_markdown
    #
    # @example With options
    #   toc = Coradoc::Markdown::TocGenerator.generate(doc,
    #     min_level: 2,
    #     max_level: 4,
    #     numbered: true
    #   )
    #
    class TocGenerator
      # Default options for TOC generation
      DEFAULT_OPTIONS = {
        min_level: 1,
        max_level: 6,
        numbered: false,
        styled: false,
        link_headings: true
      }.freeze

      # Represents a single TOC entry
      class Entry
        attr_accessor :id, :text, :level, :children, :number

        def initialize(id:, text:, level:, number: nil)
          @id = id
          @text = text
          @level = level
          @number = number
          @children = []
        end

        def to_markdown(indent: 0)
          prefix = '  ' * indent
          link = @id && @id != @text ? "[#{@text}](##{@id})" : @text
          number_prefix = @number ? "#{@number} " : ''
          "#{prefix}* #{number_prefix}#{link}\n".tap do |result|
            @children.each do |child|
              result << child.to_markdown(indent: indent + 1)
            end
          end
        end

        # Convert entry to hash representation
        # @return [Hash] Hash with id, text, level, number, and optional children
        def to_h
          result = { id: @id, text: @text, level: @level, number: @number }
          result[:children] = @children.map(&:to_h) unless @children.empty?
          result
        end
      end

      # Generate a TOC from a document
      #
      # @param document [Coradoc::Markdown::Document] The document to process
      # @param options [Hash] Generation options
      # @option options [Integer] :min_level (1) Minimum heading level to include
      # @option options [Integer] :max_level (6) Maximum heading level to include
      # @option options [Boolean] :numbered (false) Whether to add section numbers
      # @option options [Boolean] :styled (false) Whether to add styling classes
      # @option options [Boolean] :link_headings (true) Whether to link to headings
      # @return [Entry, nil] The root TOC entry or nil if no headings
      def self.generate(document, options = {})
        new(options).generate(document)
      end

      # Generate TOC as Markdown string
      #
      # @param document [Coradoc::Markdown::Document] The document to process
      # @param options [Hash] Generation options
      # @return [String] Markdown-formatted TOC
      def self.generate_markdown(document, options = {})
        toc = generate(document, options)
        toc ? toc.to_markdown : ''
      end

      # Generate TOC as array structure
      #
      # @param document [Coradoc::Markdown::Document] The document to process
      # @param options [Hash] Generation options
      # @return [Array<Hash>] Array of TOC entries
      def self.generate_array(document, options = {})
        toc = generate(document, options)
        return [] unless toc

        toc.children.map(&:to_h)
      end

      def initialize(options = {})
        @options = DEFAULT_OPTIONS.merge(options)
        @min_level = @options[:min_level]
        @max_level = @options[:max_level]
        @numbered = @options[:numbered]
      end

      # Generate TOC from document
      #
      # @param document [Coradoc::Markdown::Document] The document
      # @return [Entry, nil] Root TOC entry
      def generate(document)
        headings = extract_headings(document)
        return nil if headings.empty?

        root = Entry.new(id: nil, text: 'Table of Contents', level: 0)
        build_toc_tree(root, headings)
        root
      end

      private

      # Extract headings from document blocks
      def extract_headings(document)
        headings = []
        return headings unless document.respond_to?(:blocks)

        Array(document.blocks).each do |block|
          if block.is_a?(Coradoc::Markdown::Heading)
            headings << block if within_level_range?(block.level)
          elsif block.respond_to?(:blocks)
            # Recursively search nested blocks
            headings.concat(extract_headings_from_nested(block))
          end
        end

        headings
      end

      def extract_headings_from_nested(block)
        headings = []
        return headings unless block.respond_to?(:blocks)

        Array(block.blocks).each do |nested|
          if nested.is_a?(Coradoc::Markdown::Heading)
            headings << nested if within_level_range?(nested.level)
          elsif nested.respond_to?(:blocks)
            headings.concat(extract_headings_from_nested(nested))
          end
        end

        headings
      end

      def within_level_range?(level)
        level >= @min_level && level <= @max_level
      end

      # Build the hierarchical TOC tree
      def build_toc_tree(root, headings)
        return if headings.empty?

        # Track section numbers for each level
        counters = {}

        # Stack of entries at each level
        stack = [root]

        headings.each do |heading|
          level = heading.level

          # Update counters
          counters[level] ||= 0
          counters[level] += 1
          # Reset counters for deeper levels
          (level + 1..6).each { |l| counters[l] = 0 }

          # Generate number if needed
          number = (generate_section_number(counters, level) if @numbered)

          # Create entry
          entry = Entry.new(
            id: heading.heading_id,
            text: extract_text(heading.text),
            level: level,
            number: number
          )

          # Find the correct parent in the stack
          stack.pop while stack.length > level - @min_level + 1

          # Add to current parent
          stack.last.children << entry

          # Push for potential children
          stack.push(entry)
        end
      end

      def generate_section_number(counters, level)
        parts = []
        (@min_level..level).each do |l|
          parts << counters[l] if counters[l]&.positive?
        end
        parts.join('.')
      end

      def extract_text(text)
        return '' if text.nil?
        return text.content.to_s if text.is_a?(Coradoc::Markdown::Text)

        text.to_s
      end
    end
  end
end
