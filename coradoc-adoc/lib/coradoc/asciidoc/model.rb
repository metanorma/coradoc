# frozen_string_literal: true

# IMPORTANT: Load Base class and Serialization module FIRST
# These register the asciidoc format with Lutaml::Model, which is needed
# before any model class can use the asciidoc DSL
require_relative 'model/base'
require_relative 'model/serialization'

module Coradoc
  module AsciiDoc
    module Model
      # Layer 0: Mixins (no dependencies)
      autoload :Anchorable, "#{__dir__}/model/anchorable"
      autoload :Attached, "#{__dir__}/model/attached"
      autoload :Spacing, "#{__dir__}/model/spacing"

      # Layer 1: Simple types (only depend on Layer 0)
      autoload :Attribute, "#{__dir__}/model/attribute"
      autoload :AttributeListAttribute, "#{__dir__}/model/attribute_list_attribute"
      autoload :NamedAttribute, "#{__dir__}/model/named_attribute"
      autoload :RejectedPositionalAttribute, "#{__dir__}/model/rejected_positional_attribute"
      autoload :AttributeList, "#{__dir__}/model/attribute_list"
      autoload :Author, "#{__dir__}/model/author"
      autoload :Revision, "#{__dir__}/model/revision"
      autoload :Break, "#{__dir__}/model/break"
      autoload :CommentBlock, "#{__dir__}/model/comment_block"
      autoload :CommentLine, "#{__dir__}/model/comment_line"
      autoload :Glossaries, "#{__dir__}/model/glossaries"
      autoload :Include, "#{__dir__}/model/include"
      autoload :Tag, "#{__dir__}/model/tag"

      # Layer 2-3: Text types
      autoload :TextElement, "#{__dir__}/model/text_element"
      autoload :Admonition, "#{__dir__}/model/admonition"
      autoload :Highlight, "#{__dir__}/model/highlight"
      autoload :LineBreak, "#{__dir__}/model/line_break"
      autoload :Title, "#{__dir__}/model/title"
      autoload :Paragraph, "#{__dir__}/model/paragraph"

      # Layer 4-5: Block and List types
      autoload :Block, "#{__dir__}/model/block"
      autoload :ContentList, "#{__dir__}/model/content_list"
      autoload :Term, "#{__dir__}/model/term"
      autoload :List, "#{__dir__}/model/list"

      # Layer 6: Structural types
      autoload :DocumentAttributes, "#{__dir__}/model/document_attributes"
      autoload :Header, "#{__dir__}/model/header"
      autoload :Section, "#{__dir__}/model/section"

      # Layer 7-8: Content types
      autoload :Audio, "#{__dir__}/model/audio"
      autoload :BibliographyEntry, "#{__dir__}/model/bibliography_entry"
      autoload :Bibliography, "#{__dir__}/model/bibliography"
      autoload :Video, "#{__dir__}/model/video"
      autoload :Image, "#{__dir__}/model/image"

      # Layer 9: Table types
      autoload :TableCell, "#{__dir__}/model/table_cell"
      autoload :TableRow, "#{__dir__}/model/table_row"
      autoload :Table, "#{__dir__}/model/table"

      # Layer 10: Inline types
      autoload :Inline, "#{__dir__}/model/inline"

      # Layer 11: Complex types
      autoload :ReviewerNote, "#{__dir__}/model/reviewer_note"

      # Layer 12: Document
      autoload :Document, "#{__dir__}/model/document"
    end
  end
end
