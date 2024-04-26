require_relative "element/title"
require_relative "element/block"
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
require_relative "element/list"
require_relative "element/inline"
require_relative "element/image"
require_relative "element/audio"
require_relative "element/video"
require_relative "element/break"

module Coradoc
  class Document
    class << self
      def from_adoc(filename)
        ast = Coradoc::Parser.parse(filename)
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

          when Coradoc::Element::Section
            @sections << element
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
      @document_attributes = options.fetch(:document_attributes,
                                           Coradoc::Element::DocumentAttributes.new)
      @header = options.fetch(:header, Coradoc::Element::Header.new(""))
      @sections = options.fetch(:sections, [])
      self
    end
  end
end
