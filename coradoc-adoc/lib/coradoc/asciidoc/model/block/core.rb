# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Block
        # Base class for block elements in AsciiDoc documents.
        #
        # Block elements are delimited content sections that can contain
        # multiple lines, titles, attributes, and attached blocks.
        #
        # Specific block types (Literal, Example, Listing, Quote, etc.) inherit
        # from this class and define their delimiter characters.
        #
        # @!attribute [r] id
        #   @return [String, nil] Optional identifier for the block
        #
        # @!attribute [r] title
        #   @return [String, Array<Coradoc::AsciiDoc::Model::Base>, nil] Block title (string or array of Model objects)
        #
        # @!attribute [r] attributes
        #   @return [Coradoc::AsciiDoc::Model::AttributeList] Block attributes
        #
        # @!attribute [r] lines
        #   @return [Array<Lutaml::Model::Type::String, Coradoc::AsciiDoc::Model::TextElement>] Block content lines
        #
        # @!attribute [r] delimiter
        #   @return [String, nil] Full delimiter string
        #
        # @!attribute [r] delimiter_char
        #   @return [String, nil] Delimiter character (e.g., "=", "-", "*", "_", "+")
        #
        # @!attribute [r] delimiter_len
        #   @return [Integer, nil] Delimiter length (number of repeated characters)
        #
        # @!attribute [r] lang
        #   @return [String, nil] Language identifier for syntax highlighting
        #
        # @!attribute [r] type_str
        #   @return [String, nil] Block type string
        #
        # @example Create a custom block
        #   block = Coradoc::AsciiDoc::Model::Block::Core.new
        #   block.delimiter_char = "-"
        #   block.delimiter_len = 4
        #   block.lines = ["Line 1", "Line 2"]
        #
        # @see Coradoc::AsciiDoc::Model::Block::Literal Literal block
        # @see Coradoc::AsciiDoc::Model::Block::Example Example block
        # @see Coradoc::AsciiDoc::Model::Block::Listing Listing block
        # @see Coradoc::AsciiDoc::Model::Block::Quote Quote block
        #
        class Core < Attached
          include Coradoc::AsciiDoc::Model::Anchorable

          attribute :id, :string
          attribute :title, :string, default: -> { nil } # Polymorphic: string or array of Model objects
          attribute :attributes, Coradoc::AsciiDoc::Model::AttributeList, default: lambda {
            Coradoc::AsciiDoc::Model::AttributeList.new
          }
          attribute :lines,
                    Lutaml::Model::Serializable,
                    collection: true,
                    initialize_empty: true,
                    polymorphic: [
                      Lutaml::Model::Type::String,
                      Coradoc::AsciiDoc::Model::TextElement
                    ]
          attribute :delimiter, :string
          attribute :delimiter_char, :string
          attribute :delimiter_len, :integer
          attribute :lang, :string
          attribute :type_str, :string

          # Override title and lines setters to accept polymorphic content without coercion

          attr_accessor :title

          attr_writer :lines

          def lines
            @lines || []
          end

          def initialize(**attributes)
            # Extract title and lines before super to avoid coercion
            title_value = attributes.delete(:title)
            lines_value = attributes.delete(:lines)
            super
            self.title = title_value if title_value
            self.lines = lines_value if lines_value
          end

          # NOTE: This module provides core block functionality.
          # Additional methods may be added as needed for specific block types.

          # Generate the title string for this block
          #
          # @return [String] The formatted title (e.g., ".Title\n")
          def gen_title
            t = serialize_content(title)
            return '' if t.nil? || t.empty?

            ".#{t}\n"
          end

          # Generate the attributes string for this block
          #
          # @return [String] The formatted attributes
          def gen_attributes
            attrs = attributes.to_adoc(show_empty: false)
            return "#{attrs}\n" unless attrs.empty?

            ''
          end

          # Generate the delimiter string for this block
          #
          # @return [String] The delimiter (e.g., "----", "====")
          # @return [String] Empty string if delimiter_char or delimiter_len is nil
          def gen_delimiter
            return '' if delimiter_char.nil? || delimiter_len.nil?

            delimiter_char * delimiter_len
          end

          # Generate the lines content for this block
          #
          # @return [String] The serialized lines
          def gen_lines
            lines.map do |line|
              serialize_content(line)
            end.join
          end
        end
      end
    end
  end
end
