# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      # Visits AsciiDoc inline content and produces CoreModel inline elements.
      #
      # Replaces the 50-line transform_inline_content case/when in ToCoreModel.
      # Handles whitespace insertion between adjacent TextElements.
      class InlineTransformVisitor
        def initialize(to_core_model)
          @to_core_model = to_core_model
        end

        def transform(content)
          visit_content(content)
        end

        private

        def visit_content(content)
          case content
          when nil then []
          when Array then visit_array(content)
          when Model::TextElement then visit_content(content.content)
          when Model::Term
            [CoreModel::TermElement.new(content: content.term.to_s)]
          when String
            content.empty? ? [] : [CoreModel::TextContent.new(text: content)]
          when Model::Base
            [visit_model(content)]
          else
            text = TextExtractVisitor.new.extract(content)
            text.empty? ? [] : [CoreModel::TextContent.new(text: text)]
          end
        end

        # Folds soft source line breaks into a single text run: when two
        # +Model::TextElement+s sit adjacent in the content array (the parser
        # emits one per source line of a paragraph), a space is inserted
        # between them so wrapped text renders as flowing prose rather than
        # concatenated words.
        #
        # The previous item must ALSO be a TextElement — if a non-text
        # inline (HardLineBreak, Passthrough, Image, etc.) sits between two
        # TextElements, the source did not have a soft break there and no
        # space should be synthesised. Without this guard, `foo +\nbar`
        # would emit `["foo", hard_break, " ", "bar"]` (stray space) and
        # `Before +pass:[RAW]+ after` would emit a double space around the
        # passthrough.
        def visit_array(items)
          result = []
          previous = nil
          items.each do |item|
            transformed = visit_content(item)
            next if transformed.empty?

            result << CoreModel::TextContent.new(text: ' ') if line_break_between?(previous, item)
            result.concat(transformed)
            previous = item
          end
          result
        end

        # Two adjacent TextElements only warrant a synthesised soft-break
        # space when the parser actually split them across a source line —
        # i.e. the previous TextElement carries a non-empty line_break.
        # Adjacent inline elements whose source was a single line
        # (e.g. text + typographic-quote + text) do NOT need a synthesised
        # space: their source adjacency is exact, and adding one would
        # introduce spurious double-spaces (TODO.bugs/15A).
        def line_break_between?(previous, current)
          return false unless previous.is_a?(Model::TextElement)
          return false if current.is_a?(Model::TextElement) && current.hard_break?

          !previous.line_break.to_s.empty?
        end

        def visit_model(model)
          @to_core_model.transform(model)
        end
      end
    end
  end
end
