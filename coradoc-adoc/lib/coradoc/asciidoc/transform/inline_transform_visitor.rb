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

        def visit_array(items)
          result = []
          items.each_with_index do |item, idx|
            transformed = visit_content(item)
            next if transformed.empty?

            needs_space = idx.positive? &&
                          item.is_a?(Model::TextElement) &&
                          item.line_break != '+'
            result << CoreModel::TextContent.new(text: ' ') if needs_space
            result.concat(transformed)
          end
          result
        end

        def visit_model(model)
          @to_core_model.transform(model)
        end
      end
    end
  end
end
