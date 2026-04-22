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
              Model::TextElement.new(content: text.to_s)
            end

            rule(text_string: subtree(:text_string)) do
              text_string.to_s
            end

            rule(text: simple(:text), line_break: simple(:line_break)) do
              Model::TextElement.new(content: text.to_s, line_break: line_break)
            end

            rule(text: sequence(:text), line_break: simple(:line_break)) do
              Model::TextElement.new(content: text, line_break: line_break)
            end

            rule(id: simple(:id), text: simple(:text)) do
              Model::TextElement.new(content: text.to_s, id: id.to_s)
            end

            rule(text: sequence(:text)) do
              Model::TextElement.new(content: text)
            end

            rule(
              id: simple(:id),
              text: simple(:text),
              line_break: simple(:line_break)
            ) do
              Model::TextElement.new(
                content: text.to_s,
                id: id.to_s,
                line_break: line_break
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
                line_break: line_break
              )
            end

            # Line break
            rule(line_break: simple(:line_break)) do
              Model::LineBreak.new(line_break:)
            end

            # Unparsed text
            rule(unparsed: simple(:text)) do
              text.to_s
            end

            # Paragraph
            rule(paragraph: subtree(:paragraph)) do
              lines = paragraph[:lines] || []
              content = lines.map do |line|
                if line.is_a?(Hash) && line.key?(:text)
                  text_content = line[:text]
                  line_break = line[:line_break]

                  transformed_text = if text_content.is_a?(Array)
                                       text_content.map do |item|
                                         if item.is_a?(Hash)
                                           Transformer.new.apply(item)
                                         else
                                           item
                                         end
                                       end
                                     else
                                       text_content
                                     end

                  Model::TextElement.new(content: transformed_text, line_break: line_break)
                else
                  line
                end
              end

              Model::Paragraph.new(
                content: content,
                id: paragraph[:id],
                attributes: paragraph[:attribute_list],
                title: paragraph[:title]
              )
            end
          end
        end
      end
    end
  end
end
