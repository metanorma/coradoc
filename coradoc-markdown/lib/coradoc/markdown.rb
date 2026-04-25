# frozen_string_literal: true

# coradoc-markdown - Markdown document model, parser, and serializer
#
# This gem provides Markdown support for the Coradoc document processing library.
# It includes:
# - Markdown Document Model (Coradoc::Markdown::*)
# - Markdown Parser (CommonMark-compliant, Parslet-based)
# - Markdown Serializer (round-trip capable)
# - Kramdown extensions support (IAL, ALD, math, TOC)
#
# @example Basic usage
#   require 'coradoc/markdown'
#
#   # Parse Markdown content
#   document = Coradoc::Markdown.parse("# Title\n\nContent")
#
#   # Serialize back to Markdown
#   output = Coradoc::Markdown.serialize(document)

require 'parslet'
require 'lutaml/model'

module Coradoc
  module Markdown
    # Error classes
    autoload :Errors, 'coradoc/markdown/errors'

    # Autoload model classes
    autoload :Base, 'coradoc/markdown/model/base'
    autoload :Document, 'coradoc/markdown/model/document'
    autoload :Heading, 'coradoc/markdown/model/heading'
    autoload :Paragraph, 'coradoc/markdown/model/paragraph'
    autoload :Text, 'coradoc/markdown/model/text'
    autoload :List, 'coradoc/markdown/model/list'
    autoload :ListItem, 'coradoc/markdown/model/list_item'
    autoload :CodeBlock, 'coradoc/markdown/model/code_block'
    autoload :Blockquote, 'coradoc/markdown/model/blockquote'
    autoload :Link, 'coradoc/markdown/model/link'
    autoload :Image, 'coradoc/markdown/model/image'
    autoload :HorizontalRule, 'coradoc/markdown/model/horizontal_rule'
    autoload :Table, 'coradoc/markdown/model/table'
    autoload :Emphasis, 'coradoc/markdown/model/emphasis'
    autoload :Strong, 'coradoc/markdown/model/strong'
    autoload :Code, 'coradoc/markdown/model/code'
    autoload :DefinitionList, 'coradoc/markdown/model/definition_list'
    autoload :DefinitionTerm, 'coradoc/markdown/model/definition_term'
    autoload :DefinitionItem, 'coradoc/markdown/model/definition_item'
    autoload :Footnote, 'coradoc/markdown/model/footnote'
    autoload :FootnoteReference, 'coradoc/markdown/model/footnote_reference'
    autoload :Abbreviation, 'coradoc/markdown/model/abbreviation'
    autoload :AttributeList, 'coradoc/markdown/model/attribute_list'
    autoload :Math, 'coradoc/markdown/model/math'
    autoload :Extension, 'coradoc/markdown/model/extension'
    autoload :Strikethrough, 'coradoc/markdown/model/strikethrough'
    autoload :Highlight, 'coradoc/markdown/model/highlight'

    # Serializer
    autoload :Serializer, 'coradoc/markdown/serializer'

    # TOC Generator
    autoload :TocGenerator, 'coradoc/markdown/toc_generator'

    # Transformer (AST to Model)
    autoload :Transformer, 'coradoc/markdown/transformer'

    # CoreModel transformers
    module Transform
      autoload :ToCoreModel, 'coradoc/markdown/transform/to_core_model'
      autoload :FromCoreModel, 'coradoc/markdown/transform/from_core_model'
    end

    # Parser module namespace
    module Parser
      autoload :BlockParser, 'coradoc/markdown/parser/block_parser'
      autoload :InlineParser, 'coradoc/markdown/parser/inline_parser'
      autoload :ParsletExtras, 'coradoc/markdown/parser/parslet_extras'
      autoload :HTML_ENTITIES, 'coradoc/markdown/parser/html_entities'
      autoload :AstProcessor, 'coradoc/markdown/parser/ast_processor'
    end

    # Shared parser utilities
    autoload :ParserUtil, 'coradoc/markdown/parser_util'

    # Convenience accessors for kramdown extension models
    class << self
      # Access AttributeList class
      def AttributeList
        @AttributeList ||= const_get(:AttributeList)
      end

      # Access Math class
      def Math
        @Math ||= const_get(:Math)
      end

      # Access Extension class
      def Extension
        @Extension ||= const_get(:Extension)
      end
    end

    class << self
      # Parse Markdown content into a Document model
      #
      # @param content [String] The Markdown content to parse
      # @param options [Hash] Parsing options
      # @return [Coradoc::Markdown::Document] The parsed document model
      def parse(content, _options = {})
        ast = Parser::BlockParser.new.parse(content)
        Transformer.transform_document(ast)
      end

      # Parse raw AST (for debugging)
      #
      # @param content [String] The Markdown content to parse
      # @return [Array] The raw AST
      def parse_ast(content)
        Parser::BlockParser.new.parse(content)
      end

      # Parse Markdown from a file
      #
      # @param filename [String] Path to the Markdown file
      # @param options [Hash] Parsing options (see #parse)
      # @return [Array] The parsed AST
      def from_file(filename, **options)
        content = File.read(filename)
        parse(content, **options)
      end

      # Parse inline Markdown content
      #
      # @param content [String] The inline Markdown content to parse
      # @return [Array] The parsed inline elements
      def parse_inline(content)
        Parser::InlineParser.new.parse(content)
      end

      # Serialize a document model to Markdown string
      #
      # @param document [Coradoc::Markdown::Document] The document to serialize
      # @param options [Hash] Serialization options
      # @return [String] The Markdown output
      def serialize(document, options = {})
        Serializer.serialize(document, options)
      end

      # Transform Markdown model to CoreModel
      #
      # @param document [Coradoc::Markdown::Document] The Markdown document
      # @return [Coradoc::CoreModel::StructuralElement] The CoreModel document
      def to_core_model(document)
        Transform::ToCoreModel.transform(document)
      end
      alias to_core to_core_model

      # Parse and transform to CoreModel in one step
      #
      # @param content [String] The Markdown content
      # @return [Coradoc::CoreModel::StructuralElement] The CoreModel document
      def parse_to_core(content)
        doc = parse(content)
        to_core_model(doc)
      end

      # Transform CoreModel to Markdown model
      #
      # @param core_document [Coradoc::CoreModel::StructuralElement] The CoreModel document
      # @return [Coradoc::Markdown::Document] The Markdown document
      def from_core_model(core_document)
        Transform::FromCoreModel.transform(core_document)
      end
    end
  end

  # Register the Markdown format with Coradoc
  register_format(:markdown, Markdown, extensions: %w[.md .markdown .mdown .mkd]) if respond_to?(:register_format)
end
