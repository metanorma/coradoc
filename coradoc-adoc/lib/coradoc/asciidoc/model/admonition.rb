# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Admonition block for AsciiDoc documents.
      #
      # Admonitions are special callout boxes that highlight important
      # information: NOTE, TIP, WARNING, CAUTION, IMPORTANT.
      #
      # @!attribute [r] content
      #   @return [String] The admonition text content
      #
      # @!attribute [r] type
      #   @return [String] The admonition type (e.g., "NOTE", "TIP", "WARNING")
      #
      # @!attribute [r] line_break
      #   @return [String] Line break character (default: "")
      #
      # @example Create a note admonition
      #   admonition = Coradoc::AsciiDoc::Model::Admonition.new
      #   admonition.type = "NOTE"
      #   admonition.content = "This is important information"
      #
      # @example Create a warning admonition
      #   admonition = Coradoc::AsciiDoc::Model::Admonition.new
      #   admonition.type = "WARNING"
      #   admonition.content = "Be careful!"
      #
      class Admonition < Attached
        attribute :content, :string
        attribute :type, :string
        attribute :line_break, :string, default: -> { '' }
      end
    end
  end
end
