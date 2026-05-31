# frozen_string_literal: true

module Coradoc
  module Html
    # Builds a CoreModel::Toc from a document's StructuralElement tree.
    #
    # Walks the section hierarchy, assigns section numbers, and returns
    # a Toc model with nested TocEntry children. Section numbers are
    # derived from tree position — single source of truth for both
    # TOC rendering and heading numbering.
    class TocBuilder
      def initialize(max_level: 6, numbered: false, section_number_levels: 3)
        @max_level = max_level
        @numbered = numbered
        @section_number_levels = section_number_levels
      end

      # Build a TocBuilder from renderer-style options hash.
      #
      # @param options [Hash] options with :section_number_levels, :toc_levels, :section_numbers
      # @return [TocBuilder]
      def self.from_options(options)
        section_number_levels = options[:section_number_levels] || 3
        toc_levels = options[:toc_levels] || 2
        max_level = [toc_levels, section_number_levels].min
        new(max_level: max_level, numbered: options[:section_numbers] == true, section_number_levels: section_number_levels)
      end

      # Build a Toc model from a document.
      #
      # @param document [CoreModel::StructuralElement] the root document
      # @return [CoreModel::Toc] the built TOC with entries and section numbers
      def build(document)
        entries = []
        counters = [0]
        collect_entries(document.children, entries, 1, counters) if document.children

        CoreModel::Toc.new(
          entries: entries,
          min_level: 1,
          max_level: @max_level,
          numbered: @numbered
        )
      end

      # Compute a mapping of section_id => section_number_string.
      # Always computes numbers regardless of the +numbered+ flag,
      # since this is used for heading annotation in the body.
      #
      # @param document [CoreModel::StructuralElement] the root document
      # @return [Hash{String => String}] mapping of section ID to number (e.g., "2.1")
      def section_number_map(document)
        map = {}
        entries = []
        counters = [0]
        collect_entries(document.children, entries, 1, counters, always_number: true) if document.children
        flatten_numbers(entries, map)
        map
      end

      private

      def collect_entries(items, entries, level, counters, always_number: false)
        return unless items && level <= @max_level

        items.each do |item|
          next unless item.is_a?(CoreModel::StructuralElement)
          next unless item.section? || item.header?

          counters[level] = (counters[level] || 0) + 1
          ((level + 1)..@section_number_levels).each { |i| counters[i] = 0 }

          use_number = always_number || @numbered
          number = use_number && level <= @section_number_levels ? counters[1..level].join('.') : nil

          children = []
          collect_entries(item.children, children, level + 1, counters, always_number: always_number) if item.children

          entries << CoreModel::TocEntry.new(
            id: entry_id(item),
            title: entry_title(item),
            level: level,
            number: number,
            children: children
          )
        end
      end

      def flatten_numbers(entries, map)
        entries.each do |entry|
          map[entry.id] = entry.number if entry.id && entry.number
          flatten_numbers(entry.children, map) if entry.children
        end
      end

      def entry_title(section)
        TitleText.resolve(section.title)
      end

      def entry_id(section)
        section.id
      end
    end
  end
end
