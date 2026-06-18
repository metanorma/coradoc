# frozen_string_literal: true

require 'parslet'
require 'parslet/convenience'

module Coradoc
  module AsciiDoc
    module Parser
      # Autoload parser modules - they will be loaded when included in Base class below
      autoload :Admonition, 'coradoc/asciidoc/parser/admonition'
      autoload :AttributeList, 'coradoc/asciidoc/parser/attribute_list'
      autoload :Bibliography, 'coradoc/asciidoc/parser/bibliography'
      autoload :Block, 'coradoc/asciidoc/parser/block'
      autoload :BlockHeader, 'coradoc/asciidoc/parser/block_header'
      autoload :Citation, 'coradoc/asciidoc/parser/citation'
      autoload :Content, 'coradoc/asciidoc/parser/content'
      autoload :DocumentAttributes, 'coradoc/asciidoc/parser/document_attributes'
      autoload :Header, 'coradoc/asciidoc/parser/header'
      autoload :Inline, 'coradoc/asciidoc/parser/inline'
      autoload :List, 'coradoc/asciidoc/parser/list'
      autoload :Paragraph, 'coradoc/asciidoc/parser/paragraph'
      autoload :RuleDispatcher, 'coradoc/asciidoc/parser/rule_dispatcher'
      autoload :Section, 'coradoc/asciidoc/parser/section'
      autoload :Table, 'coradoc/asciidoc/parser/table'
      autoload :Term, 'coradoc/asciidoc/parser/term'
      autoload :Text, 'coradoc/asciidoc/parser/text'
      autoload :Stem, 'coradoc/asciidoc/parser/stem'

      class Base < Parslet::Parser
        include Admonition
        include AttributeList
        include Bibliography
        include Block
        include BlockHeader
        include Citation
        include Content
        include DocumentAttributes
        include Header
        include Inline
        include List
        include Paragraph
        include Section
        include Table
        include Term
        include Text
        include Stem

        root :document

        rule(:document) do
          (
            header.as(:header) |
            document_attributes |
            section |
            admonition_line |
            bib_entry |
            block |
            block_image |
            comment_block |
            comment_line |
            include_directive |
            list |
            table.as(:table) |
            page_break.as(:page_break) |
            paragraph |
            tag |
            empty_line.as(:line_break) |
            any.as(:unparsed)
          ).repeat.as(:document)
        end

        # Parse an AsciiDoc file
        # @param filename [String] The filename of the Asciidoc file to parse
        # @return [Hash] The parsed AST object
        def self.parse_file(filename)
          parse(File.read(filename))
        end

        # Parse an AsciiDoc string
        # @param string [String] The Asciidoc string to parse
        # @return [Hash] The parsed AST object
        def self.parse(string)
          new.parse(string)
        rescue Parslet::ParseFailed => e
          warn e.parse_failure_cause.ascii_tree
        end

        def rule_dispatch(rule_name, *, **)
          RuleDispatcher.dispatch(self, rule_name, *, **)
        end
      end

      # Wrap every parser rule for Parslet memoization. Must run after all
      # parser modules are included in Base so that instance_method(rule_name)
      # finds the methods defined by every module.
      RuleDispatcher.apply(Base)
    end
  end
end
