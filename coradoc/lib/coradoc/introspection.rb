# frozen_string_literal: true

module Coradoc
  # Document introspection: file metadata, validation, stats. Extracted
  # from the top-level Coradoc façade so the document-counting visitor
  # and file-metadata helpers have their own home. Public API on
  # +Coradoc+ delegates here.
  module Introspection
    autoload :ElementCounter, "#{__dir__}/introspection/element_counter"

    class << self
      def file_info(path)
        fmt = FormatCatalog.detect_format(path)
        info = { size: File.size(path), format: fmt }
        info[:lines] = File.foreach(path).count unless FormatCatalog.binary_format?(fmt)
        info
      end

      def validate_file(path, format: nil)
        doc = Pipeline.parse_file(path, format: format)

        schema = Validation::SchemaGenerator.generate(doc.class)
        return schema.validate(doc) if schema

        Validation::Result.new
      end

      def document_stats(doc)
        stats = {}
        stats[:title] = doc.title if doc.title

        if doc.is_a?(CoreModel::StructuralElement)
          stats[:child_count] = count_elements(doc)
          stats[:element_counts] = count_element_types(doc)
        end

        stats
      end

      def describe_element(elem)
        return elem.to_s unless elem.is_a?(CoreModel::Base)

        type = elem.class.name.split('::').last
        if elem.title
          "#{type}: #{elem.title}"
        elsif elem.is_a?(CoreModel::Block) && elem.content
          preview = elem.content.to_s[0..50]
          preview += '...' if elem.content.to_s.length > 50
          "#{type}: #{preview}"
        else
          type
        end
      end

      private

      def count_elements(doc)
        return 0 unless doc.is_a?(CoreModel::StructuralElement)

        doc.children.sum do |child|
          1 + (child.is_a?(CoreModel::StructuralElement) ? count_elements(child) : 0)
        end
      end

      def count_element_types(doc)
        counter = ElementCounter.new
        counter.visit(doc)
        counter.counts.reject { |_, v| v.zero? }
      end
    end
  end
end
