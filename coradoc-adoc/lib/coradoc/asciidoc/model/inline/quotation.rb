# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Inline
        # Quotation (single-quoted text) inline element for AsciiDoc documents.
        #
        # Quoted text is rendered with single backticks: `quoted text`.
        #
        # @!attribute [r] content
        #   @return [String] The text content to quote
        #
        # @example Create quoted text
        #   quote = Coradoc::AsciiDoc::Model::Inline::Quotation.new
        #   quote.content = "He said"
        #   quote.to_adoc # => "`He said`"
        #
        class Quotation < Base
          attribute :content, :string
        end
      end
    end
  end
end
