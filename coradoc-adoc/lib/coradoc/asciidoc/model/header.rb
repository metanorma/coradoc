# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Document header containing title and metadata.
      #
      # The Header represents the document-level metadata including the main title,
      # author information, and revision details. This corresponds to the AsciiDoc
      # header line (e.g., `= Document Title`) and associated metadata.
      #
      # @!attribute [r] title
      #   @return [String] The main document title
      # @!attribute [r] author
      #   @return [Author, nil] Document author information
      # @!attribute [r] revision
      #   @return [Revision, nil] Document revision information (version, date)
      #
      # @example Create a simple header
      #   header = Coradoc::AsciiDoc::Model::Header.new(title: "My Document")
      #
      # @example Create a header with author and revision
      #   header = Coradoc::AsciiDoc::Model::Header.new(
      #     title: "My Document",
      #     author: Coradoc::AsciiDoc::Model::Author.new("John Doe"),
      #     revision: Coradoc::AsciiDoc::Model::Revision.new("1.0", "2024-01-01")
      #   )
      #
      class Header < Base
        include Coradoc::AsciiDoc::Model::Anchorable

        attribute :title, Coradoc::AsciiDoc::Model::Title
        attribute :author, Coradoc::AsciiDoc::Model::Author
        attribute :revision, Coradoc::AsciiDoc::Model::Revision

        def validate
          validate_author_type
          validate_revision_type
        end

        private

        def validate_author_type
          return if author.nil? || author.is_a?(Coradoc::AsciiDoc::Model::Author)

          raise TypeError, "author must be a Coradoc::AsciiDoc::Model::Author, got #{author.class}"
        end

        def validate_revision_type
          return if revision.nil? || revision.is_a?(Coradoc::AsciiDoc::Model::Revision)

          raise TypeError, "revision must be a Coradoc::AsciiDoc::Model::Revision, got #{revision.class}"
        end
      end
    end
  end
end
