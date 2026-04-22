# frozen_string_literal: true

require_relative 'resolver'

module Coradoc
  module AsciiDoc
    module Model
      # Document model representing an AsciiDoc document.
      #
      # The Document class is the main container for parsed AsciiDoc content.
      # It holds the document's header, attributes, and sections (blocks, lists, etc.).
      #
      # @!attribute [r] document_attributes
      #   @return [DocumentAttributes] Document-level attributes like author, date, etc.
      # @!attribute [r] header
      #   @return [Header] Document header containing title and metadata
      # @!attribute [r] sections
      #   @return [Array<Base>] Document content blocks (sections, paragraphs, lists, etc.)
      #
      # @example Create a new document
      #   doc = Coradoc::AsciiDoc::Model::Document.new(
      #     header: Coradoc::AsciiDoc::Model::Header.new(title: "My Document"),
      #     sections: [Coradoc::AsciiDoc::Model::Paragraph.new("Hello World")]
      #   )
      #
      # @example Parse and serialize
      #   doc = Coradoc.parse("= Title\n\nContent")
      #   doc.to_adoc # => "= Title\n\nContent"
      #
      # @example Expand includes
      #   doc = Coradoc.parse_file("main.adoc")
      #   expanded = doc.expand_includes("/path/to/docs")
      #
      # @example Freeze document with unified resolution
      #   frozen = doc.freeze(base_dir: "/path/to/docs", includes: true, images: :reference)
      #
      class Document < Base
        attribute :document_attributes,
                  Coradoc::AsciiDoc::Model::DocumentAttributes,
                  default: lambda {
                    Coradoc::AsciiDoc::Model::DocumentAttributes.new
                  }
        attribute :header,
                  Coradoc::AsciiDoc::Model::Header,
                  default: lambda {
                    Coradoc::AsciiDoc::Model::Header.new(
                      title: Coradoc::AsciiDoc::Model::Title.new(content: '')
                    )
                  }

        attribute :sections,
                  Coradoc::AsciiDoc::Model::Base,
                  collection: true,
                  initialize_empty: true,
                  polymorphic: [
                    Coradoc::AsciiDoc::Model::Admonition,
                    Coradoc::AsciiDoc::Model::Audio,
                    Coradoc::AsciiDoc::Model::BibliographyEntry,
                    Coradoc::AsciiDoc::Model::Block::Core,
                    Coradoc::AsciiDoc::Model::Image::BlockImage,
                    Coradoc::AsciiDoc::Model::CommentBlock,
                    Coradoc::AsciiDoc::Model::CommentLine,
                    Coradoc::AsciiDoc::Model::Include,
                    Coradoc::AsciiDoc::Model::LineBreak,
                    Coradoc::AsciiDoc::Model::List::Core,
                    Coradoc::AsciiDoc::Model::Paragraph,
                    Coradoc::AsciiDoc::Model::Table,
                    Coradoc::AsciiDoc::Model::Tag,
                    Coradoc::AsciiDoc::Model::Video
                  ]

        # @param [Integer] index The index of the section to retrieve
        # @return [Coradoc::AsciiDoc::Model::Base] The section at the specified index
        def [](index)
          sections[index]
        end

        # @param [Integer] index The index of the section to set
        # @param [Coradoc::AsciiDoc::Model::Base] value The section to set at the specified index
        # @return [Coradoc::AsciiDoc::Model::Base] The section that was set
        def []=(index, value)
          sections[index] = value
        end

        # Expand include directives in the document
        # @param base_dir [String] Base directory for resolving relative includes
        # @return [Coradoc::AsciiDoc::Model::Document] A new document with includes expanded
        def expand_includes(base_dir = '.')
          freeze(base_dir: base_dir, includes: true, images: :reference, media: :reference)
        end

        # Freeze the document by resolving external references.
        #
        # This method creates a NEW document with resolved references.
        # The original document is never modified (immutable principle).
        #
        # @param options [Hash] Resolution options
        # @option options [String] :base_dir Base directory for relative paths (default: ".")
        # @option options [Boolean] :includes Resolve include:: directives (default: true)
        # @option options [Symbol] :images Image resolution: :reference, :copy, :embed (default: :reference)
        # @option options [Symbol] :media Media resolution: :reference, :copy (default: :reference)
        # @option options [String] :output_dir Output directory for :copy mode
        # @option options [Integer] :max_recursion Maximum recursion depth for includes (default: 10)
        # @return [Document] NEW document with resolved references
        #
        # @example Resolve includes only
        #   frozen = doc.freeze(base_dir: "/docs", includes: true)
        #
        # @example Create self-contained document
        #   frozen = doc.freeze(
        #     base_dir: "/docs",
        #     includes: true,
        #     images: :embed,
        #     output_dir: "/output"
        #   )
        #
        def freeze(options = {})
          resolver = Resolver.new(options)
          base_dir = options[:base_dir] || '.'
          resolver.resolve_document(self, base_dir)
        end

        class << self
          def from_ast(elements)
            sections = []
            document_attributes = nil
            header = nil

            elements.each do |element|
              case element
              when Coradoc::AsciiDoc::Model::DocumentAttributes
                document_attributes = element

              when Coradoc::AsciiDoc::Model::Header
                header = element

              when Coradoc::AsciiDoc::Model::Base
                sections << element

              else
                warn "Unknown element type: #{element.class}"
                warn "Element: #{element.inspect}"
              end
            end

            # Merge standalone LineBreak elements into the previous element's line_break
            merge_line_breaks(sections)

            # Only pass non-nil values to preserve defaults
            attrs = { sections: sections }
            attrs[:document_attributes] = document_attributes if document_attributes
            attrs[:header] = header if header

            new(attrs)
          end

          private

          def merge_line_breaks(sections)
            return if sections.empty?

            # Skip leading LineBreak elements
            sections.shift while sections.first.is_a?(Coradoc::AsciiDoc::Model::LineBreak)

            i = 0
            while i < sections.length
              # If current element is a LineBreak and there's a previous element
              if sections[i].is_a?(Coradoc::AsciiDoc::Model::LineBreak) && i.positive?
                prev = sections[i - 1]
                line_break = sections[i]

                # Skip consecutive LineBreaks
                if prev.is_a?(Coradoc::AsciiDoc::Model::LineBreak)
                  sections.delete_at(i)
                  next
                end

                # Merge the line break into the previous element if it has a line_break attribute
                if prev.respond_to?(:line_break=)
                  prev.line_break = prev.line_break.to_s + line_break.line_break.to_s
                  sections.delete_at(i)
                  # Don't increment i since we deleted an element
                  next
                else
                  # Keep as standalone if no suitable previous element
                  i += 1
                end
              else
                i += 1
              end
            end
          end
        end
      end
    end
  end
end
