# frozen_string_literal: true

require_relative 'resolvable'

module Coradoc
  module AsciiDoc
    module Model
      # Include directive element for AsciiDoc documents.
      #
      # Include directives allow incorporating content from external files
      # into the current document at processing time.
      #
      # @!attribute [r] path
      #   @return [String] The path to the file to include
      #
      # @!attribute [r] attributes
      #   @return [Coradoc::AsciiDoc::Model::AttributeList] Include attributes
      #
      # @!attribute [r] line_break
      #   @return [String] Line break character (default: "\n")
      #
      # @example Create an include directive
      #   inc = Coradoc::AsciiDoc::Model::Include.new
      #   inc.path = "chapter1.adoc"
      #   inc.to_adoc # => "include::chapter1.adoc[]\n"
      #
      class Include < Base
        include Resolvable

        attribute :path, :string
        attribute :attributes, Coradoc::AsciiDoc::Model::AttributeList, default: lambda {
          Coradoc::AsciiDoc::Model::AttributeList.new
        }
        attribute :line_break, :string, default: -> { "\n" }

        # @return [String] the path to the included file
        def reference_path
          path
        end

        # @return [Symbol] the reference type
        def reference_type
          :include
        end

        # @return [Hash] include options (leveloffset, lines, tags, etc.)
        def reference_options
          options = {}
          if attributes.respond_to?(:named)
            attributes.named.each do |attr|
              case attr.name.to_s
              when 'leveloffset'
                options[:leveloffset] = attr.value
              when 'lines'
                options[:lines] = attr.value
              when 'tags'
                options[:tags] = attr.value.to_s.split(';')
              end
            end
          end
          options
        end
      end
    end
  end
end
