# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      # Trigger loading of all serializer registrations
      #
      # Each serializer file self-registers when loaded via autoload.
      # This module triggers the autoload of all serializers by accessing
      # their constants, which causes the registration code in each file to execute.
      module Registrations
        class << self
          # Load all serializers to trigger their registration
          # rubocop:disable Lint/Void - Constants are referenced to trigger autoload
          def load_all!
            # Top-level serializers
            Serializers::Base
            Serializers::Admonition
            Serializers::Attribute
            Serializers::AttributeList
            Serializers::AttributeListAttribute
            Serializers::Audio
            Serializers::Author
            Serializers::Bibliography
            Serializers::BibliographyEntry
            Serializers::Break
            Serializers::CommentBlock
            Serializers::CommentLine
            Serializers::Document
            Serializers::DocumentAttributes
            Serializers::Header
            Serializers::Highlight
            Serializers::Include
            Serializers::LineBreak
            Serializers::List
            Serializers::NamedAttribute
            Serializers::Paragraph
            Serializers::ReviewerNote
            Serializers::Revision
            Serializers::Section
            Serializers::Tag
            Serializers::TableCell
            Serializers::TableRow
            Serializers::Table
            Serializers::Term
            Serializers::TextElement
            Serializers::Title
            Serializers::Video

            # Block serializers
            Serializers::Block
            Serializers::Block::Core
            Serializers::Block::Example
            Serializers::Block::Listing
            Serializers::Block::Literal
            Serializers::Block::Open
            Serializers::Block::Pass
            Serializers::Block::Quote
            Serializers::Block::ReviewerComment
            Serializers::Block::Side
            Serializers::Block::SourceCode

            # Image serializers
            Serializers::Image
            Serializers::Image::Core

            # Inline serializers
            Serializers::Inline
            Serializers::Inline::Anchor
            Serializers::Inline::AttributeReference
            Serializers::Inline::Bold
            Serializers::Inline::CrossReference
            Serializers::Inline::CrossReferenceArg
            Serializers::Inline::Footnote
            Serializers::Inline::HardLineBreak
            Serializers::Inline::Highlight
            Serializers::Inline::Italic
            Serializers::Inline::Link
            Serializers::Inline::Monospace
            Serializers::Inline::Quotation
            Serializers::Inline::Small
            Serializers::Inline::Span
            Serializers::Inline::Stem
            Serializers::Inline::Strikethrough
            Serializers::Inline::Subscript
            Serializers::Inline::Superscript
            Serializers::Inline::Underline

            # List serializers
            Serializers::List
            Serializers::List::Core
            Serializers::List::Definition
            Serializers::List::DefinitionItem
            Serializers::List::Item
            Serializers::List::Ordered
            Serializers::List::Unordered

            true
          end
          # rubocop:enable Lint/Void
        end

        # Auto-load all on module inclusion
        load_all!
      end
    end
  end
end
