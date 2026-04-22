# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Inline
        # Hard line break inline element for AsciiDoc documents.
        #
        # Hard line breaks force a line break at a specific point.
        # Rendered as a plus sign at the end of a line: +.
        #
        # @example Create a hard line break
        #   break = Coradoc::AsciiDoc::Model::Inline::HardLineBreak.new
        #   break.to_adoc # => " +"
        #
        class HardLineBreak < Base
        end
      end
    end
  end
end
