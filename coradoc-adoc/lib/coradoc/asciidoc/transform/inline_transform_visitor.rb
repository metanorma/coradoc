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

            result << CoreModel::TextContent.new(text: ' ') if soft_break_before?(previous, item)
            result.concat(transformed)
            previous = item
          end
          result
        end

        def soft_break_before?(previous, current)
          previous.is_a?(Model::TextElement) &&
            current.is_a?(Model::TextElement) &&
            current.line_break != '+'
        end

        def visit_model(model)
          @to_core_model.transform(model)
        end
      end
    end
  end
end
