# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Represents a Table of Contents in a document
    #
    # TOC provides hierarchical navigation structure for documents.
    # It can be auto-generated from document sections or manually defined.
    #
    # @example Creating a TOC from sections
    #   toc = CoreModel::Toc.new(
    #     entries: [
    #       CoreModel::TocEntry.new(
    #         id: 'section-1',
    #         title: 'Section 1',
    #         level: 1,
    #         children: [
    #           CoreModel::TocEntry.new(id: 'subsection', title: 'Subsection', level: 2)
    #         ]
    #       )
    #     ]
    #   )
    #
    # @example Creating a TOC with configuration
    #   toc = CoreModel::Toc.new(
    #     entries: entries,
    #     min_level: 1,
    #     max_level: 3,
    #     numbered: true
    #   )
    class Toc < Base
      # @!attribute entries
      #   @return [Array<TocEntry>] the TOC entries
      #   Declared as Base (not :string): TocEntry is defined below and
      #   lutaml-model never re-registers a re-declared attribute — the
      #   old remove_method reopen did not fix the :string cast, so every
      #   entry was stringified at construction (issue #255). Base-typed
      #   collections preserve TocEntry instances (the pattern used by
      #   Block/Table children).
      attribute :entries, Base, collection: true

      # @!attribute min_level
      #   @return [Integer] minimum heading level to include (default: 1)
      attribute :min_level, :integer, default: -> { 1 }

      # @!attribute max_level
      #   @return [Integer] maximum heading level to include (default: 6)
      attribute :max_level, :integer, default: -> { 6 }

      # @!attribute numbered
      #   @return [Boolean] whether to include section numbers
      attribute :numbered, :boolean, default: -> { false }

      # @!attribute styled
      #   @return [Boolean] whether to include styling
      attribute :styled, :boolean, default: -> { false }

      private

      def comparable_attributes
        super + %i[entries min_level max_level numbered styled]
      end
    end

    # Represents a single entry in a Table of Contents
    #
    # Each entry represents a heading/section and can contain
    # nested child entries.
    class TocEntry < Base
      # @!attribute id
      #   @return [String, nil] the anchor ID for linking
      attribute :id, :string

      # @!attribute title
      #   @return [String, nil] the heading text
      attribute :title, :string

      # @!attribute level
      #   @return [Integer] the heading level (1-6)
      attribute :level, :integer, default: -> { 1 }

      # @!attribute number
      #   @return [String, nil] the section number (e.g., "1.2.3")
      attribute :number, :string

      # @!attribute children
      #   @return [Array<TocEntry>] nested child entries
      #   Base-typed for the same reason as Toc#entries (self-referential;
      #   see issue #255).
      attribute :children, Base, collection: true

      private

      def comparable_attributes
        super + %i[id title level number children]
      end
    end

  end
end
