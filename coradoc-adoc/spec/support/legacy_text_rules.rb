# frozen_string_literal: true

# Frozen copy of the hand-written text rules that the M3 bindings
# retired (transformer/text_rules.rb at 5c1c689). The bound-vs-unbound
# differential applies them to a Transformer subclass as the reference the
# bindings must match.
module Coradoc
  module AsciiDoc
    class Transformer < Parsanol::Transform
      # Module containing text and paragraph transformation rules
      module LegacyTextRules
        def self.apply(transformer_class)
          transformer_class.class_eval do
            # Text Model
            rule(text: simple(:text)) do
              Model::TextElement.new(
                content: text.to_s
              )
            end

            rule(text_string: subtree(:text_string)) do
              text_string.to_s
            end

            rule(text: simple(:text), line_break: simple(:line_break)) do
              Model::TextElement.new(
                content: text.to_s,
                line_break: line_break
              )
            end

            rule(text: sequence(:text), line_break: simple(:line_break)) do
              Model::TextElement.new(
                content: text,
                line_break: line_break
              )
            end

            rule(id: simple(:id), text: simple(:text)) do
              Model::TextElement.new(
                content: text.to_s,
                id: id.to_s
              )
            end

            rule(text: sequence(:text)) do
              Model::TextElement.new(
                content: text
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
              Model::LineBreak.new(
                line_break:
              )
            end

            # Unparsed text
            rule(unparsed: simple(:text)) do
              text.to_s
            end

            # Paragraph is bound: see Bindings::PARAGRAPH.
          end
        end
      end
    end
  end
end
