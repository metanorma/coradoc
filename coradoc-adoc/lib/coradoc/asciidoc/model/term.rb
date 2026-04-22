# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Term element for AsciiDoc definition lists.
      #
      # Terms are the items being defined in definition lists.
      # Each term has a text value and can have an optional type.
      #
      # @!attribute [r] term
      #   @return [String] The term text being defined
      #
      # @!attribute [r] type
      #   @return [String] The term type/category
      #
      # @!attribute [r] lang
      #   @return [String] Language code (default: "en")
      #
      # @!attribute [r] line_break
      #   @return [String] Line break character (default: "")
      #
      # @example Create a term
      #   term = Coradoc::AsciiDoc::Model::Term.new
      #   term.term = "ASCII"
      #   term.type = "acronym"
      #
      # @see Coradoc::AsciiDoc::Model::List::Definition Definition lists
      #
      class Term < Base
        attribute :term, :string
        attribute :type, :string
        attribute :lang, :string, default: -> { 'en' }
        attribute :line_break, :string, default: -> { '' }

        def validate
          errors = super

          errors << Lutaml::Model::Error.new('Term cannot be nil or empty') if term.nil? || term.empty?

          errors << Lutaml::Model::Error.new('Type cannot be nil or empty') if type.nil? || type.empty?

          errors
        end
      end
    end
  end
end
