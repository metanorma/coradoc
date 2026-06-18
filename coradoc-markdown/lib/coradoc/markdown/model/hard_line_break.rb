# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Markdown
    # Hard line break — forces a line break within a paragraph, distinct
    # from a new paragraph.
    #
    # Two strategy modes (configurable via the serializer config):
    #   - `:trailing_space` (CommonMark default): two trailing spaces
    #   - `:backslash` (GFM alternative): backslash before newline
    #
    # AsciiDoc `+` line-continuation maps to this element.
    class HardLineBreak < Base
      def initialize(**_rest)
        super
      end
    end
  end
end
