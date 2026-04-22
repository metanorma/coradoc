# frozen_string_literal: true

module Coradoc
  # CoreModel namespace for schema-agnostic document models
  #
  # The CoreModel layer provides a clean separation between parsing (syntax recognition)
  # and schema-specific models. It builds semantic document structure from generic AST
  # without knowledge of specific document schemas (ISO, OSCAL, etc.).
  #
  # @example Building a document from AST
  #   ast = parser.parse(asciidoc_text)
  #   document = CoreModel::Builder.build(ast)
  #
  # @see CoreModel::Builder for AST to model conversion
  # @see CoreModel::Base for base functionality
  module CoreModel
    # Autoload submodules lazily using relative paths
    autoload :Base, "#{__dir__}/core_model/base"
    autoload :Block, "#{__dir__}/core_model/block"
    autoload :AnnotationBlock, "#{__dir__}/core_model/annotation_block"
    autoload :ListBlock, "#{__dir__}/core_model/list_block"
    autoload :ListItem, "#{__dir__}/core_model/list_item"
    autoload :InlineElement, "#{__dir__}/core_model/inline_element"
    autoload :StructuralElement, "#{__dir__}/core_model/structural_element"
    autoload :Builder, "#{__dir__}/core_model/builder"
    autoload :Table, "#{__dir__}/core_model/table"
    autoload :TableCell, "#{__dir__}/core_model/table"
    autoload :TableRow, "#{__dir__}/core_model/table"
    autoload :Image, "#{__dir__}/core_model/image"
    autoload :Term, "#{__dir__}/core_model/term"
    autoload :ElementAttribute, "#{__dir__}/core_model/element_attribute"
    autoload :Metadata, "#{__dir__}/core_model/metadata"
    autoload :MetadataEntry, "#{__dir__}/core_model/metadata"
    autoload :Footnote, "#{__dir__}/core_model/footnote"
    autoload :FootnoteReference, "#{__dir__}/core_model/footnote"
    autoload :Abbreviation, "#{__dir__}/core_model/footnote"
    autoload :DefinitionItem, "#{__dir__}/core_model/definition_item"
    autoload :DefinitionList, "#{__dir__}/core_model/definition_list"
    autoload :Toc, "#{__dir__}/core_model/toc"
    autoload :TocEntry, "#{__dir__}/core_model/toc"
    autoload :TocGenerator, "#{__dir__}/core_model/toc_generator"
    autoload :Bibliography, "#{__dir__}/core_model/bibliography"
    autoload :BibliographyEntry, "#{__dir__}/core_model/bibliography_entry"
  end
end
