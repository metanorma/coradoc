# frozen_string_literal: true

require_relative "base"
require_relative "title"
require_relative "document_attributes"
require_relative "header"
require_relative "section"

module Coradoc
  module Model
    class Document < Base
      attribute :document_attributes,
                Coradoc::Model::DocumentAttributes,
                default: -> {
                  Coradoc::Model::DocumentAttributes.new
                }
      attribute :header,
                Coradoc::Model::Header,
                default: -> {
                  Coradoc::Model::Header.new(title: "")
                }

      attribute :sections,
                Coradoc::Model::Base,
                collection: true,
                initialize_empty: true,
                polymorphic: [
                  Coradoc::Model::Admonition,
                  Coradoc::Model::Audio,
                  Coradoc::Model::BibliographyEntry,
                  Coradoc::Model::Block::Core,
                  Coradoc::Model::Image::BlockImage,
                  Coradoc::Model::CommentBlock,
                  Coradoc::Model::CommentLine,
                  Coradoc::Model::Include,
                  Coradoc::Model::List::Core,
                  Coradoc::Model::Paragraph,
                  Coradoc::Model::Table,
                  Coradoc::Model::Tag,
                  Coradoc::Model::Video,
                ]

      asciidoc do
        map_model to: Coradoc::Document
        map_attribute :document_attributes, to: :document_attributes
        map_attribute :header, to: :header
        map_attribute :sections, to: :sections
      end

      def to_asciidoc
        [header, document_attributes, sections].compact.map { |element|
          # element.to_asciidoc
          Coradoc::Generator.gen_adoc(element)
          # end.join("\n")
        }.join

        # Coradoc::Generator.gen_adoc(header) +
        #   Coradoc::Generator.gen_adoc(document_attributes) +
        #   Coradoc::Generator.gen_adoc(sections)
      end

      class << self
        def from_ast(elements)
          @sections = []
          # require 'pry'
          # binding.pry

          elements.each do |element|
            case element
            when Coradoc::Model::DocumentAttributes
              @document_attributes = element

            when Coradoc::Model::Header
              @header = element

            # when Coradoc::Model::Section
            #   @sections << element

            when Coradoc::Model::Base
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
    end
  end
end
