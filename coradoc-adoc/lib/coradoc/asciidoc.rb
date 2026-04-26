# frozen_string_literal: true

require 'parslet'
require 'lutaml/model'
require 'coradoc/core_model' # Required for CoreModel types in transformers

module Coradoc
  # Utility module autoload
  autoload :Util, "#{__dir__}/util"

  module AsciiDoc
    # Base error class for AsciiDoc gem, inheriting from Coradoc::Error
    # for consistent error handling across all gems
    class Error < Coradoc::Error; end
  end
end

# Load version and parse_error (small files, needed immediately)
require_relative 'asciidoc/version'
require_relative 'asciidoc/parse_error'

# Autoload main components (lazy loading)
module Coradoc
  module AsciiDoc
    autoload :Model, "#{__dir__}/asciidoc/model"
    autoload :Parser, "#{__dir__}/asciidoc/parser"
    autoload :Transformer, "#{__dir__}/asciidoc/transformer"
    autoload :Serializer, "#{__dir__}/asciidoc/serializer"
    autoload :Transform, "#{__dir__}/asciidoc/transform"
  end
end

# Now define the module methods after all dependencies are loaded
module Coradoc
  module AsciiDoc
    class << self
      # Parse AsciiDoc text and return an AsciiDoc document model
      #
      # @param text [String] AsciiDoc content to parse
      # @return [Coradoc::AsciiDoc::Model::Document] Parsed document model
      def parse(text)
        ast = Coradoc::AsciiDoc::Parser::Base.parse(text)
        Coradoc::AsciiDoc::Transformer.transform(ast)
      end

      # Parse AsciiDoc text and convert to CoreModel
      #
      # @param text [String] AsciiDoc content to parse
      # @return [Coradoc::CoreModel::Document] CoreModel document
      def parse_to_core(text)
        doc = parse(text)
        Coradoc::AsciiDoc::Transform::ToCoreModel.transform(doc)
      end

      # Serialize a document model to AsciiDoc string
      #
      # @param document [Coradoc::AsciiDoc::Model::Document, Coradoc::CoreModel::Base]
      #   Document model to serialize
      # @return [String] AsciiDoc representation
      def serialize(document)
        case document
        when Coradoc::CoreModel::Base
          # Convert CoreModel to AsciiDoc model first
          adoc_model = Coradoc::AsciiDoc::Transform::FromCoreModel.transform(document)
          adoc_model.to_adoc
        else
          document.to_adoc
        end
      end
    end

    # Backward-compatible aliases for model classes
    # These allow tests and legacy code to use Coradoc::AsciiDoc::Document
    # instead of Coradoc::AsciiDoc::Model::Document
    Base = Model::Base
    Document = Model::Document
    Section = Model::Section
    Paragraph = Model::Paragraph
    TextElement = Model::TextElement
    Title = Model::Title
    Header = Model::Header
    Admonition = Model::Admonition
    Table = Model::Table
    TableRow = Model::TableRow
    TableCell = Model::TableCell
    Term = Model::Term
    Break = Model::Break
    Audio = Model::Audio
    Video = Model::Video
    Bibliography = Model::Bibliography
    BibliographyEntry = Model::BibliographyEntry
    CommentBlock = Model::CommentBlock
    CommentLine = Model::CommentLine
    LineBreak = Model::LineBreak
    Include = Model::Include
    Attribute = Model::Attribute
    AttributeList = Model::AttributeList
    Author = Model::Author
    Revision = Model::Revision
    NamedAttribute = Model::NamedAttribute
    ContentList = Model::ContentList
    Tag = Model::Tag
    Highlight = Model::Highlight
    DocumentAttributes = Model::DocumentAttributes

    # Namespace aliases for nested modules
    Inline = Model::Inline
    Block = Model::Block
    List = Model::List
    Image = Model::Image

    # Module aliases for mixins
    Anchorable = Model::Anchorable
    Attached = Model::Attached
    Spacing = Model::Spacing
  end
end

# Register the AsciiDoc format with Coradoc after module is fully defined
# Use conditional registration to handle load order issues
Coradoc.register_format(:asciidoc, Coradoc::AsciiDoc) if Coradoc.respond_to?(:register_format)

# Backward-compatibility: Coradoc::Model is now Coradoc::AsciiDoc::Model
# This alias is provided for legacy code that hasn't been updated
Coradoc::Model = Coradoc::AsciiDoc::Model unless defined?(Coradoc::Model)
