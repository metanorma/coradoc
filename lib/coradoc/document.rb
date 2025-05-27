require_relative "element/base"
require_relative "element/title"
require_relative "element/block"
require_relative "element/bibliography"
require_relative "element/bibliography_entry"
require_relative "element/comment_block"
require_relative "element/comment_line"
require_relative "element/include"
require_relative "element/section"
require_relative "element/attribute"
require_relative "element/attribute_list"
require_relative "element/admonition"
require_relative "element/text_element"
require_relative "element/author"
require_relative "element/revision"
require_relative "element/header"
require_relative "element/document_attributes"
require_relative "element/paragraph"
require_relative "element/table"
require_relative "element/tag"
require_relative "element/list"
require_relative "element/inline"
require_relative "element/image"
require_relative "element/audio"
require_relative "element/video"
require_relative "element/break"
require_relative "element/term"

module Coradoc
  class Document
    class << self
      # @param [String] filename The filename of the Asciidoc file to parse
      # @return [Coradoc::Document] The parsed Coradoc::Document object
      def from_file(filename)
        ast = Coradoc::Parser.parse_file(filename)
        Coradoc::Transformer.transform(ast)
      end

      # @param [String] string The Asciidoc string to parse
      # @param [Hash] options Options for parsing
      # @return [Coradoc::Document] The parsed Coradoc::Document object
      def parse(string, _options = {})
        # Parse the Asciidoc string into an AST
        ast = Coradoc::Parser.parse(string)

        # Transform the AST into a Coradoc::Document object
        Coradoc::Transformer.transform(ast)
      end

      def from_ast(elements)
        @sections = []

        elements.each do |element|
          case element
          when Coradoc::Element::DocumentAttributes
            @document_attributes = element

          when Coradoc::Element::Header
            @header = element

          # when Coradoc::Element::Section
          #   @sections << element

          when Coradoc::Element::Base
            @sections << element

          else
            warn "Unknown element type: #{element.class}"
            warn "Element: #{element.inspect}"
          end
        end

        new(
          document_attributes: @document_attributes,
          header: @header,
          sections: @sections,
        )
      end
    end

    attr_accessor :header, :document_attributes, :sections

    def initialize(options = {})
      @document_attributes = options.fetch(
        :document_attributes,
        Coradoc::Element::DocumentAttributes.new,
      )
      @header = options.fetch(:header, Coradoc::Element::Header.new(title: ""))
      @sections = options.fetch(:sections, [])
      self
    end

    # XXX: useful at all??
    # @param [Integer] index The index of the section to retrieve
    # @return [Coradoc::Element::Section] The section at the specified index
    def [](index)
      @sections[index]
    end

    # XXX: useful at all??
    # @param [Integer] index The index of the section to retrieve
    # @param [Coradoc::Element::Section] value The section to set at the specified index
    # @return [Coradoc::Element::Section] The section at the specified index
    def []=(index, value)
      @sections[index] = value
    end

    # Mainly for conversion between its Lutaml Model equivalent
    # @return [Hash] The document as a hash
    def to_h
      {
        header: @header,
        document_attributes: @document_attributes,
        sections: @sections,
      }
    end

    # @return [String] The document as an Asciidoc string
    def to_adoc
      Coradoc::Generator.gen_adoc(@header) +
        Coradoc::Generator.gen_adoc(@document_attributes) +
        Coradoc::Generator.gen_adoc(@sections)
    end
  end
end
