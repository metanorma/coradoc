# frozen_string_literal: true

require 'fileutils'

module Coradoc
  module AsciiDoc
    module Model
      # SplitDocument provides functionality to split a single AsciiDoc document
      # into multiple files with include directives.
      #
      # This is the inverse operation of include resolution - instead of expanding
      # includes into a single document, we split a document into multiple files.
      #
      # @example Split a document into section files
      #   doc = Coradoc::AsciiDoc.parse(content)
      #   splitter = SplitDocument.new(doc, section_dir: "sections")
      #   splitter.write!(output_dir)
      #
      class SplitDocument
        # @return [Document] The original document
        attr_reader :original

        # @return [Hash] Configuration options
        attr_reader :options

        # Create a new SplitDocument instance.
        #
        # @param document [Document] The document to split
        # @param options [Hash] Configuration options
        # @option options [String] :section_dir Directory name for section files (default: "sections")
        # @option options [Integer] :split_at_level Heading level to split at (default: 1, meaning == sections)
        # @option options [Symbol] :naming Naming convention: :numbered, :titled (default: :numbered)
        # @option options [String] :file_extension File extension for section files (default: ".adoc")
        #
        def initialize(document, options = {})
          @original = document
          @options = {
            section_dir: 'sections',
            split_at_level: 1, # Split at level 1 (== in AsciiDoc)
            naming: :numbered,
            file_extension: '.adoc'
          }.merge(options)
        end

        # Build the main document with include directives.
        #
        # @return [Document] NEW document with Include nodes instead of sections
        #
        def main_document
          @main_document ||= build_main_document
        end

        # Build a hash of section files to be written.
        #
        # @return [Hash<String, String>] Map of relative_path => content
        #
        def section_files
          @section_files ||= build_section_files
        end

        # Write the split document to disk.
        #
        # @param base_dir [String] Base directory to write files to
        # @param main_filename [String] Filename for the main document (default: "document.adoc")
        # @return [Array<String>] List of paths that were written
        #
        def write!(base_dir, main_filename: 'document.adoc')
          written = []
          FileUtils.mkdir_p(base_dir)

          # Write section files
          section_dir = File.join(base_dir, options[:section_dir])
          FileUtils.mkdir_p(section_dir)

          section_files.each do |relative_path, content|
            path = File.join(base_dir, relative_path)
            FileUtils.mkdir_p(File.dirname(path))
            File.write(path, content)
            written << path
          end

          # Write main document
          main_path = File.join(base_dir, main_filename)
          File.write(main_path, main_document.to_adoc)
          written << main_path

          written
        end

        # Serialize the main document to AsciiDoc.
        #
        # @return [String] AsciiDoc representation
        #
        def to_adoc
          main_document.to_adoc
        end

        private

        def build_main_document
          # Start with header and document attributes
          main_sections = []

          # Track which sections are being split out
          section_index = 0

          original.sections.each do |section|
            if should_split?(section)
              # Create an include directive for this section
              filename = generate_section_filename(section, section_index)
              include_path = "#{options[:section_dir]}/#{filename}"

              include_node = Include.new(
                path: include_path,
                line_break: "\n"
              )
              main_sections << include_node
              section_index += 1
            else
              # Keep non-splittable sections in the main document
              main_sections << section
            end
          end

          Document.new(
            document_attributes: original.document_attributes,
            header: original.header,
            sections: main_sections
          )
        end

        def build_section_files
          files = {}
          section_index = 0

          original.sections.each do |section|
            next unless should_split?(section)

            filename = generate_section_filename(section, section_index)
            content = serialize_section(section)
            files[filename] = content
            section_index += 1
          end

          files
        end

        def should_split?(section)
          # Split sections that are at the configured level
          return false unless section.respond_to?(:level)

          level = section.level
          level >= options[:split_at_level]
        end

        def generate_section_filename(section, index)
          extension = options[:file_extension]

          case options[:naming]
          when :numbered
            # Generate numbered filenames like 01-scope.adoc, 02-normref.adoc
            prefix = format('%02d', index + 1)

            # Try to get a slug from the section title
            slug = extract_slug(section)
            slug = "section-#{index + 1}" if slug.nil? || slug.empty?

            "#{prefix}-#{slug}#{extension}"

          when :titled
            # Generate titled filenames like scope.adoc, normative-references.adoc
            slug = extract_slug(section)
            slug = "section-#{index + 1}" if slug.nil? || slug.empty?

            "#{slug}#{extension}"

          else
            "section-#{index + 1}#{extension}"
          end
        end

        def extract_slug(section)
          return nil unless section.respond_to?(:title)

          title = section.title
          return nil if title.nil?

          # Convert title to slug
          title_str = title.is_a?(String) ? title : title.to_s

          # Downcase, replace spaces with hyphens, remove special chars
          slug = title_str.downcase
                          .gsub(/\s+/, '-')
                          .gsub(/[^a-z0-9-]/, '')
                          .gsub(/-+/, '-')
                          .gsub(/^-|-$/, '')

          # Limit length
          slug = slug[0..50] if slug.length > 50

          slug
        end

        def serialize_section(section)
          section.to_adoc
        end
      end
    end
  end
end
