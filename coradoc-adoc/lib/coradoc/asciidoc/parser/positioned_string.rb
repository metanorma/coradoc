# frozen_string_literal: true

require 'parsanol'

module Coradoc
  module AsciiDoc
    module Parser
      # An immutable String carrying its byte offset and source input.
      #
      # The native engine hands pooled, mutable Parsanol::Slice objects
      # back in the parse tree; storing those in document models is
      # unsafe (the pool resets them) and they fail serializer type
      # checks. TreeMaterializer converts every Slice into a
      # PositionedString at the GrammarBackend boundary, so models only
      # ever see Strings — while SourceLineExtractor can still recover
      # positions (line_and_column delegates the computation to a
      # throwaway Slice).
      class PositionedString < String
        attr_reader :byte_position, :source_input

        def initialize(content, byte_position: 0, source_input: nil)
          super(content)
          @byte_position = byte_position
          @source_input = source_input
        end

        def self.from_slice(slice)
          new(slice.to_s, byte_position: slice.offset, source_input: slice.input)
        end

        def line_and_column
          raise ArgumentError, 'Line/column requires input' unless @source_input

          @line_and_column ||= Parsanol::Slice.new(@byte_position, to_s,
                                                   @source_input).line_and_column
        end
      end
    end
  end
end
