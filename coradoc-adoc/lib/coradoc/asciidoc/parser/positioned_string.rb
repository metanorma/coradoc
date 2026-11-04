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

        # Newline byte offsets per source, computed once. A Slice's own
        # line_and_column re-slices and re-counts the whole prefix on
        # every call, which made recovering the line of each element
        # quadratic in the document size.
        NEWLINE_INDEX = ObjectSpace::WeakMap.new
        private_constant :NEWLINE_INDEX

        def self.newline_offsets(source)
          NEWLINE_INDEX[source] ||= begin
            bytes = source.b
            offsets = []
            at = -1
            offsets << at while (at = bytes.index("\n".b, at + 1))
            offsets
          end
        end

        def line_and_column
          raise ArgumentError, 'Line/column requires input' unless @source_input
          return @line_and_column if @line_and_column

          @line_and_column = if @source_input.is_a?(String)
                               indexed_line_and_column
                             else
                               Parsanol::Slice.new(@byte_position, to_s, @source_input).line_and_column
                             end
        end

        private

        def indexed_line_and_column
          offsets = self.class.newline_offsets(@source_input)
          before = offsets.bsearch_index { |off| off >= @byte_position } || offsets.size
          line_start = before.zero? ? 0 : offsets[before - 1] + 1
          tail = @source_input.byteslice(line_start, @byte_position - line_start)
          [before + 1, tail.dup.force_encoding(Encoding::UTF_8).length + 1]
        end
      end
    end
  end
end
