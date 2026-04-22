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
      autoload :Citation, 'coradoc/asciidoc/parser/citation'
      autoload :Content, 'coradoc/asciidoc/parser/content'
      autoload :DocumentAttributes, 'coradoc/asciidoc/parser/document_attributes'
      autoload :Header, 'coradoc/asciidoc/parser/header'
      autoload :Inline, 'coradoc/asciidoc/parser/inline'
      autoload :List, 'coradoc/asciidoc/parser/list'
      autoload :Paragraph, 'coradoc/asciidoc/parser/paragraph'
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

        def rule_dispatch(rule_name, *args, **kwargs)
          @dispatch_data ||= {}
          dispatch_key = [rule_name, args, kwargs.to_a.sort]
          dispatch_hash = dispatch_key.hash.abs
          unless @dispatch_data.key?(dispatch_hash)
            alias_name = :"#{rule_name}_#{dispatch_hash}"
            Coradoc::AsciiDoc::Parser::Base.class_exec do
              rule(alias_name) do
                send(rule_name, *args, **kwargs)
              end
            end
            @dispatch_data[dispatch_hash] = alias_name
          end
          dispatch_method = @dispatch_data[dispatch_hash]
          send(dispatch_method)
        end

        def self.config(key)
          # NOTE: These are internal dispatch configuration options for the parser:
          # - add_dispatch: Enables automatic method dispatching
          # - with_params: Supports parameterized rule invocation
          c = {
            add_dispatch: true,
            with_params: true
          }

          raise ArgumentError, "Unknown config key: #{key}. Available keys: #{c.keys.join(', ')}" unless c.key?(key)

          c[key]
        end

        # Collect parser methods from all parser modules (excluding Base, Cache, and FixFiles)
        # Base is the parser class, Cache is a utility class, FixFiles is a utility module
        parser_constants = Coradoc::AsciiDoc::Parser.constants - %i[Base Cache FixFiles]
        parser_methods = parser_constants.each_with_object({}) do |const, acc|
          rule_names = Coradoc::AsciiDoc::Parser.const_get(const).instance_methods
          rule_names.each do |rule_name|
            acc[rule_name] ||= []
            acc[rule_name] << const
          end
        end

        # Warn about duplicated parser methods:
        parser_methods.each do |rule_name, defn_sites|
          count = defn_sites.length
          if count > 1
            defn_site_constants = defn_sites.map { |const| Coradoc::AsciiDoc::Parser.const_get(const) }
            Coradoc::Logger.warn "Parser method '#{rule_name}' is defined #{count} times in #{defn_site_constants.join(', ')}"
          end
        end

        parser_methods.each_key do |rule_name|
          params = Coradoc::AsciiDoc::Parser::Base.instance_method(rule_name).parameters
          if config(:add_dispatch) && params == []
            alias_name = :"alias_nondispatch_#{rule_name}"
            Coradoc::AsciiDoc::Parser::Base.class_exec do
              alias_method alias_name, rule_name
              rule(rule_name) do
                send(alias_name)
              end
            end
          elsif config(:add_dispatch) && config(:with_params)
            alias_name = :"alias_dispatch_#{rule_name}"
            Coradoc::AsciiDoc::Parser::Base.class_exec do
              alias_method alias_name, rule_name
              define_method(rule_name) do |*args, **kwargs|
                rule_dispatch(alias_name, *args, **kwargs)
              end
            end
          end
        end
      end
    end
  end
end
