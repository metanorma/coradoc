# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    class Transformer < Parslet::Transform
      # Module containing text and paragraph transformation rules
      module TextRules
        def self.apply(transformer_class)
          transformer_class.class_eval do
            # Text Model
            rule(text: simple(:text)) do
              Model::TextElement.new(
                content: text.to_s,
                source_line: Transformer::SourceLineExtractor.extract(text)
              )
            end

            rule(text_string: subtree(:text_string)) do
              text_string.to_s
            end

            rule(text: simple(:text), line_break: simple(:line_break)) do
              Model::TextElement.new(
                content: text.to_s,
                line_break: line_break,
                source_line: Transformer::SourceLineExtractor.extract(text)
              )
            end

            rule(text: sequence(:text), line_break: simple(:line_break)) do
              Model::TextElement.new(
                content: text,
                line_break: line_break,
                source_line: Transformer::SourceLineExtractor.extract(text)
              )
            end

            rule(id: simple(:id), text: simple(:text)) do
              Model::TextElement.new(
                content: text.to_s,
                id: id.to_s,
                source_line: Transformer::SourceLineExtractor.extract(id)
              )
            end

            rule(text: sequence(:text)) do
              Model::TextElement.new(
                content: text,
                source_line: Transformer::SourceLineExtractor.extract(text)
              )
            end

            rule(
              id: simple(:id),
              text: simple(:text),
              line_break: simple(:line_break)
            ) do
              Model::TextElement.new(
                content: text.to_s,
                id: id.to_s,
                line_break: line_break,
                source_line: Transformer::SourceLineExtractor.extract(id)
              )
            end

            rule(
              id: simple(:id),
              text: sequence(:text),
              line_break: simple(:line_break)
            ) do
              Model::TextElement.new(
                content: text,
                id: id.to_s,
                line_break: line_break,
                source_line: Transformer::SourceLineExtractor.extract(id)
              )
            end

            # Line break
            rule(line_break: simple(:line_break)) do
              Model::LineBreak.new(
                line_break:,
                source_line: Transformer::SourceLineExtractor.extract(line_break)
              )
            end

            # Unparsed text
            rule(unparsed: simple(:text)) do
              text.to_s
            end

            # Paragraph
            rule(paragraph: subtree(:paragraph)) do
              Model::Paragraph.new(
                content: Transformer.lines_to_text_elements(paragraph[:lines]),
                id: paragraph[:id],
                attributes: paragraph[:attribute_list],
                title: paragraph[:title],
                source_line: Transformer::SourceLineExtractor.extract(paragraph)
              )
            end
          end
        end
      end
    end
  end
end
