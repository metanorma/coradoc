# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Section element for organizing document content hierarchically.
      #
      # Sections represent the hierarchical structure of an AsciiDoc document.
      # They can contain nested subsections, paragraphs, and other content.
      #
      # @!attribute [r] id
      #   @return [String, nil] Optional identifier for the section
      # @!attribute [r] content
      #   @return [String, nil] Optional string content (typically unused, see contents)
      # @!attribute [r] title
      #   @return [Title] Section title
      # @!attribute [r] attrs
      #   @return [Array<NamedAttribute>] Additional named attributes
      # @!attribute [r] contents
      #   @return [Array<Paragraph>] Paragraph content within this section
      # @!attribute [r] sections
      #   @return [Array<Section>] Nested subsections
      #
      # @example Create a section
      #   section = Coradoc::AsciiDoc::Model::Section.new(
      #     title: Coradoc::AsciiDoc::Model::Title.new("Chapter 1"),
      #     contents: [Coradoc::AsciiDoc::Model::Paragraph.new("Content here")]
      #   )
      #
      # @example Create nested sections
      #   parent = Coradoc::AsciiDoc::Model::Section.new(
      #     title: Coradoc::AsciiDoc::Model::Title.new("Parent Section")
      #   )
      #   child = Coradoc::AsciiDoc::Model::Section.new(
      #     title: Coradoc::AsciiDoc::Model::Title.new("Child Section")
      #   )
      #   parent.sections << child
      #
      class Section < Base
        include Coradoc::AsciiDoc::Model::Anchorable

        attribute :id, :string
        attribute :content, :string
        attribute :title, Coradoc::AsciiDoc::Model::Title
        attribute :attrs,
                  Coradoc::AsciiDoc::Model::NamedAttribute,
                  collection: true,
                  initialize_empty: true
        attribute :contents,
                  Coradoc::AsciiDoc::Model::Paragraph,
                  collection: true,
                  initialize_empty: true
        attribute :sections,
                  Coradoc::AsciiDoc::Model::Section,
                  collection: true,
                  initialize_empty: true
        # attribute :anchor, Coradoc::AsciiDoc::Model::Inline::Anchor

        # Allow setting level directly during initialization
        def initialize(**attributes)
          level_value = attributes.delete(:level)
          super
          if level_value && title
            title.level_int = level_value
          elsif level_value
            self.title = Coradoc::AsciiDoc::Model::Title.new(content: '', level_int: level_value)
          end
        end

        def validate
          validate_title_type
          super
        end

        # Get the section level from the title
        # @return [Integer, nil] The section level (0-5 for standard sections)
        def level
          title&.level_int
        end

        # Set the section level on the title
        # @param value [Integer] The section level
        def level=(value)
          if title
            title.level_int = value
          else
            self.title = Coradoc::AsciiDoc::Model::Title.new(content: '', level_int: value)
          end
        end

        def safe_to_collapse?
          title.nil? && sections.empty?
        end

        private

        def validate_title_type
          return if title.nil? || title.is_a?(Coradoc::AsciiDoc::Model::Title)

          raise TypeError, "title must be a Coradoc::AsciiDoc::Model::Title, got #{title.class}"
        end
      end
    end
  end
end
