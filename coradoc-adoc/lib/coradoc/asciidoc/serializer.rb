# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    # Serializer module for converting AsciiDoc models to AsciiDoc text
    module Serializer
      autoload :AdocSerializer, "#{__dir__}/serializer/adoc_serializer"
      autoload :ElementRegistry, "#{__dir__}/serializer/element_registry"
      autoload :FallbackSerializer, "#{__dir__}/serializer/fallback_serializer"
      autoload :Formatter, "#{__dir__}/serializer/formatter"
      autoload :SpacingStrategy, "#{__dir__}/serializer/spacing_strategy"

      class << self
        # Serialize a model to AsciiDoc format
        # @param model [Coradoc::AsciiDoc::Model::Base, Array, String] Model to serialize
        # @param options [Hash] Serialization options
        # @return [String] AsciiDoc representation
        def serialize(model, options = {})
          AdocSerializer.serialize(model, options)
        end
      end
    end
  end
end

# Set up Serializers module with autoloads
module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        # Autoload core serializers (flat structure)
        autoload :Base, 'coradoc/asciidoc/serializer/serializers/base'
        autoload :Admonition, 'coradoc/asciidoc/serializer/serializers/admonition'
        autoload :Attribute, 'coradoc/asciidoc/serializer/serializers/attribute'
        autoload :AttributeList, 'coradoc/asciidoc/serializer/serializers/attribute_list'
        autoload :AttributeListAttribute, 'coradoc/asciidoc/serializer/serializers/attribute_list_attribute'
        autoload :Audio, 'coradoc/asciidoc/serializer/serializers/audio'
        autoload :Author, 'coradoc/asciidoc/serializer/serializers/author'
        autoload :Bibliography, 'coradoc/asciidoc/serializer/serializers/bibliography'
        autoload :BibliographyEntry, 'coradoc/asciidoc/serializer/serializers/bibliography_entry'
        autoload :Break, 'coradoc/asciidoc/serializer/serializers/break'
        autoload :CommentBlock, 'coradoc/asciidoc/serializer/serializers/comment_block'
        autoload :CommentLine, 'coradoc/asciidoc/serializer/serializers/comment_line'
        autoload :Document, 'coradoc/asciidoc/serializer/serializers/document'
        autoload :DocumentAttributes, 'coradoc/asciidoc/serializer/serializers/document_attributes'
        autoload :Header, 'coradoc/asciidoc/serializer/serializers/header'
        autoload :Highlight, 'coradoc/asciidoc/serializer/serializers/highlight'
        autoload :Include, 'coradoc/asciidoc/serializer/serializers/include'
        autoload :LineBreak, 'coradoc/asciidoc/serializer/serializers/line_break'
        autoload :NamedAttribute, 'coradoc/asciidoc/serializer/serializers/named_attribute'
        autoload :Paragraph, 'coradoc/asciidoc/serializer/serializers/paragraph'
        autoload :ReviewerNote, 'coradoc/asciidoc/serializer/serializers/reviewer_note'
        autoload :Revision, 'coradoc/asciidoc/serializer/serializers/revision'
        autoload :Section, 'coradoc/asciidoc/serializer/serializers/section'
        autoload :Tag, 'coradoc/asciidoc/serializer/serializers/tag'
        autoload :TableCell, 'coradoc/asciidoc/serializer/serializers/table_cell'
        autoload :TableRow, 'coradoc/asciidoc/serializer/serializers/table_row'
        autoload :Table, 'coradoc/asciidoc/serializer/serializers/table'
        autoload :Term, 'coradoc/asciidoc/serializer/serializers/term'
        autoload :TextElement, 'coradoc/asciidoc/serializer/serializers/text_element'
        autoload :Title, 'coradoc/asciidoc/serializer/serializers/title'
        autoload :Video, 'coradoc/asciidoc/serializer/serializers/video'

        # Autoload submodules (each manages its own autoloads)
        autoload :Block, 'coradoc/asciidoc/serializer/serializers/block'
        autoload :Image, 'coradoc/asciidoc/serializer/serializers/image'
        autoload :Inline, 'coradoc/asciidoc/serializer/serializers/inline'
        autoload :List, 'coradoc/asciidoc/serializer/serializers/list'
      end
    end
  end
end

# Load registrations last (triggers autoload of all serializers)
require_relative 'serializer/registrations'
