# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Inline
        # Underline inline text formatting for AsciiDoc documents.
        #
        # Underlined text is rendered with underscores: [u]#text#.
        #
        # @!attribute [r] text
        #   @return [String] The text content to underline
        #
        # @example Create underlined text
        #   underline = Coradoc::AsciiDoc::Model::Inline::Underline.new
        #   underline.text = "Underlined"
        #   underline.to_adoc # => "[u]#Underlined#"
        #
        class Underline < Base
          attribute :text, :string
        end
      end
    end
  end
end
