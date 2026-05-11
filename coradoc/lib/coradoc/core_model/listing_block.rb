# frozen_string_literal: true

module Coradoc
  module CoreModel
    # Listing block — a delimited block for listing/content without source language
    #
    # Distinct from SourceBlock: a listing has no language annotation.
    # When a language is present, SourceBlock should be used instead.
    class ListingBlock < Block
      def self.semantic_type = :listing
    end
  end
end
