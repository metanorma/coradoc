# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Inline
        # Anchor inline element for creating cross-reference targets in AsciiDoc documents.
        #
        # Anchors create reference points that can be linked to from other parts
        # of the document using cross-references.
        #
        # @!attribute [r] id
        #   @return [String] The anchor identifier
        #
        # @example Create an anchor
        #   anchor = Coradoc::AsciiDoc::Model::Inline::Anchor.new
        #   anchor.id = "section1"
        #   anchor.to_adoc # => "[[section1]]"
        #
        # @example Validation fails without id
        #   anchor = Coradoc::AsciiDoc::Model::Inline::Anchor.new
        #   anchor.validate # Returns validation errors
        #
        # @see Coradoc::AsciiDoc::Model::Anchorable Mixin for adding anchor support
        # @see Coradoc::AsciiDoc::Model::Inline::CrossReference Linking to anchors
        #
        class Anchor < Base
          attribute :id, :string

          def validate
            errors = super
            return unless id.nil? || id.empty?

            errors <<
              Lutaml::Model::Error.new('ID cannot be nil or empty for Anchor')
          end
        end
      end
    end
  end
end
