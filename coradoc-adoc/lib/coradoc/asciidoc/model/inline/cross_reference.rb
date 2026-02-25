# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Inline
        # Cross-reference (xref) inline element for AsciiDoc documents.
        #
        # Cross-references create links to other sections or documents.
        #
        # @!attribute [r] href
        #   @return [String] The target reference ID
        #
        # @!attribute [r] args
        #   @return [Array<String>] Optional reference arguments
        #
        # @example Create a cross-reference
        #   xref = Coradoc::AsciiDoc::Model::Inline::CrossReference.new
        #   xref.href = "section-id"
        #   xref.to_adoc # => "<<section-id>>"
        #
        class CrossReference < Base
          attribute :href, :string
          attribute :args, :string, collection: true
        end
      end
    end
  end
end
