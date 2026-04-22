# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Thematic break elements for AsciiDoc documents.
      #
      module Break
        # Thematic break (horizontal rule) for AsciiDoc documents.
        #
        # Represented by a line of three or more asterisks ('***') in AsciiDoc.
        # Used to separate content sections visually.
        #
        # @example Create a thematic break
        #   break = Coradoc::AsciiDoc::Model::Break::ThematicBreak.new
        #
        # @example Serialize to AsciiDoc
        #   break = Coradoc::AsciiDoc::Model::Break::ThematicBreak.new
        #   break.to_adoc # => "'''\n"
        #
        class ThematicBreak < Base
        end
      end
    end
  end
end
