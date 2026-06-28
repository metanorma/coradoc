# frozen_string_literal: true

require 'parslet'

module Coradoc
  module AsciiDoc
    class Transformer < Parslet::Transform
      # Walks a Parslet AST subtree (Hash/Array/Slice/String/Model) and
      # returns the 1-indexed source line of the first +Parslet::Slice+
      # or Model::Base#source_line it finds.
      #
      # Parslet preserves byte offsets on every matched slice
      # (+slice.line_and_column+ returns +[line, column]+); the
      # transformer receives these slices in the AST but most rules
      # discard the position when building Model objects. This helper
      # recovers the start line of any subtree so transformer rules
      # can populate +Model::Base#source_line+ without changing the
      # parser.
      #
      # Handles two distinct shapes:
      #   * Pre-transform AST (Hash/Array of Parslet::Slice) — used by
      #     rules that bind raw slices via +simple(:x)+.
      #   * Post-transform Model tree (Model::Base instances whose
      #     +source_line+ was populated by an earlier rule) — used by
      #     rules that bind via +subtree(:x)+ and receive already-
      #     transformed content.
      #
      # Returns nil when no position is found (programmatic input,
      # already-stripped ASTs, etc.) — callers should treat nil as
      # "source position unavailable".
      module SourceLineExtractor
        module_function

        def extract(node)
          case node
          when Parslet::Slice then line_of(node)
          when Coradoc::AsciiDoc::Model::Base then node.source_line
          when Hash then extract_from_hash(node)
          when Array then extract_from_array(node)
          else nil
          end
        end

        def line_of(slice)
          line, _column = slice.line_and_column
          line
        end

        def extract_from_hash(hash)
          hash.each_value do |value|
            line = extract(value)
            return line if line
          end
          nil
        end

        def extract_from_array(array)
          array.each do |value|
            line = extract(value)
            return line if line
          end
          nil
        end
      end
    end
  end
end
