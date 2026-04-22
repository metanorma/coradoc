# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Table of Contents Generator for CoreModel documents
    #
    # Generates a Toc model from CoreModel::StructuralElement documents.
    # Supports configurable level ranges and section numbering.
    #
    # @example Basic usage
    #   doc = Coradoc::CoreModel::StructuralElement.new(
    #     element_type: 'document',
    #     children: [section1, section2]
    #   )
    #   toc = CoreModel::TocGenerator.generate(doc)
    #
    # @example With options
    #   toc = CoreModel::TocGenerator.generate(doc,
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
        styled: false
      }.freeze

      class << self
        # Generate a Toc from a CoreModel document
        #
        # @param document [CoreModel::StructuralElement] The document to process
        # @param options [Hash] Generation options
        # @option options [Integer] :min_level (1) Minimum heading level
        # @option options [Integer] :max_level (6) Maximum heading level
        # @option options [Boolean] :numbered (false) Add section numbers
        # @option options [Boolean] :styled (false) Add styling
        # @return [CoreModel::Toc, nil] The generated TOC or nil if no sections
        def generate(document, options = {})
          opts = DEFAULT_OPTIONS.merge(options)
          entries = extract_toc_entries(document, opts)

          return nil if entries.empty?

          CoreModel::Toc.new(
            entries: entries,
            min_level: opts[:min_level],
            max_level: opts[:max_level],
            numbered: opts[:numbered],
            styled: opts[:styled]
          )
        end

        private

        # Extract TOC entries from a document
        def extract_toc_entries(document, options)
          sections = find_sections(document, options[:min_level], options[:max_level])
          return [] if sections.empty?

          # Track section numbers
          counters = {}

          build_entries(sections, options, counters)
        end

        # Find all sections in the document within level range
        def find_sections(element, min_level, max_level)
          sections = []
          return sections unless element.respond_to?(:children)

          Array(element.children).each do |child|
            next unless child.is_a?(CoreModel::StructuralElement)

            if child.element_type == 'section'
              level = child.level || 1
              sections << { element: child, level: level } if level >= min_level && level <= max_level

              # Also search nested sections
            else
              # Search children for sections
            end
            sections.concat(find_sections(child, min_level, max_level))
          end

          sections
        end

        # Build hierarchical TOC entries from flat section list
        def build_entries(sections, options, counters)
          return [] if sections.empty?

          entries = []
          options[:min_level]

          # Stack for tracking parent entries at each level
          stack = { options[:min_level] - 1 => nil }

          sections.each do |section_info|
            element = section_info[:element]
            level = section_info[:level]

            # Update counters
            counters[level] ||= 0
            counters[level] += 1
            # Reset deeper level counters
            (level + 1..6).each { |l| counters[l] = 0 }

            # Generate number if needed
            number = (generate_number(counters, options[:min_level], level) if options[:numbered])

            entry = CoreModel::TocEntry.new(
              id: element.id,
              title: element.title,
              level: level,
              number: number,
              children: []
            )

            # Find parent at previous level
            parent_level = level - 1
            parent_level -= 1 while parent_level >= options[:min_level] - 1 && !stack.key?(parent_level)

            if stack[parent_level]
              stack[parent_level].children << entry
            else
              entries << entry
            end

            # Add to stack for potential children
            stack[level] = entry
          end

          entries
        end

        def generate_number(counters, min_level, current_level)
          parts = []
          (min_level..current_level).each do |l|
            parts << counters[l] if counters[l]&.positive?
          end
          parts.join('.')
        end
      end
    end
  end
end
