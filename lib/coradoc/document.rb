require "coradoc/document/title"
require "coradoc/document/block"
require "coradoc/document/section"
require "coradoc/document/attribute"
require "coradoc/document/admonition"
require "coradoc/document/text_element"
require "coradoc/document/author"
require "coradoc/document/revision"
require "coradoc/document/header"
require "coradoc/document/bibdata"
require "coradoc/document/paragraph"
require "coradoc/document/table"
require "coradoc/document/list"

require "coradoc/document/inline"
require "coradoc/document/audio"
require "coradoc/document/video"
require "coradoc/document/break"

module Coradoc
  module Document
    class << self
      attr_reader :header, :bibdata, :sections

      def from_adoc(filename)
        ast = Coradoc::Parser.parse(filename)
        Coradoc::Transformer.transform(ast)
      end

      def from_ast(elements)
        @sections = []

        elements.each do |element|
          if element.is_a?(Coradoc::Document::Bibdata)
            @bibdata = element
          end

          if element.is_a?(Coradoc::Document::Header)
            @header = element
          end

          if element.is_a?(Coradoc::Document::Section)
            @sections << element
          end
        end

        self
      end
    end
  end
end
