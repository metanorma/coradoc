# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Inline
        # Small text inline element for AsciiDoc documents.
        #
        # Small text is rendered with a size role: [.small]#text#.
        #
        # @!attribute [r] text
        #   @return [String] The text content to make smaller
        #
        # @example Create small text
        #   small = Coradoc::AsciiDoc::Model::Inline::Small.new
        #   small.text = "Fine print"
        #   small.to_adoc # => "[.small]#Fine print#"
        #
        class Small < Base
          attribute :text, :string
        end
      end
    end
  end
end
