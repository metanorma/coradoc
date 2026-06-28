# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    class Transformer < Parslet::Transform
      # Module containing miscellaneous transformation rules
      module MiscRules
        def self.apply(transformer_class)
          transformer_class.class_eval do
            # Comments
            rule(comment_line: {
                   comment_text: simple(:comment_text),
                   line_break: simple(:line_break)
                 }) do
              Model::CommentLine.new(
                text: comment_text,
                line_break: line_break,
                source_line: SourceLineExtractor.extract(comment_text)
              )
            end

            rule(comment_block: { comment_text: simple(:comment_text) }) do
              Model::CommentBlock.new(
                text: comment_text,
                source_line: SourceLineExtractor.extract(comment_text)
              )
            end

            # Page break
            rule(page_break: simple(:page_break)) do
              Model::Break::PageBreak.new(
                source_line: SourceLineExtractor.extract(page_break)
              )
            end

            # Tag
            rule(tag: subtree(:tag)) do
              Model::Tag.new(
                name: tag[:name],
                attrs: tag[:attribute_list],
                line_break: tag[:line_break],
                prefix: tag[:prefix],
                source_line: SourceLineExtractor.extract(tag)
              )
            end

            # AttributeList
            rule(
              named: {
                named_key: simple(:key),
                named_value: simple(:value)
              }
            ) do
              Model::Attribute.new(key: key.to_s, value: value.to_s)
            end

            rule(positional: simple(:positional)) do
              positional
            end

            rule(attribute_array: nil) do
              Model::AttributeList.new
            end

            rule(attribute_array: sequence(:attributes)) do
              attr_list = Model::AttributeList.new(
                source_line: SourceLineExtractor.extract(attributes)
              )
              attributes.each do |a|
                case a
                when Parslet::Slice
                  attr_list.add_positional(a.to_s)
                when String
                  attr_list.add_positional(a)
                when Model::Attribute
                  attr_list.add_named(a.key, a.value)
                end
              end
              attr_list
            end

            # Attribute with line_break
            rule(
              key: simple(:key),
              value: simple(:value),
              line_break: simple(:line_break)
            ) do
              Model::Attribute.new(
                key: key.to_s,
                value: value.to_s,
                line_break: line_break.to_s
              )
            end

            # Attribute without line_break
            rule(
              key: simple(:key),
              value: simple(:value)
            ) do
              Model::Attribute.new(
                key: key.to_s,
                value: value.to_s
              )
            end

            # Document attributes
            rule(document_attributes: sequence(:document_attribute)) do
              Model::DocumentAttributes.new(data: document_attribute)
            end

            # Include
            rule(
              include: {
                path: simple(:path),
                attribute_list: simple(:attribute_list),
                line_break: simple(:line_break)
              }
            ) do
              Model::Include.new(
                path: path.to_s,
                attributes: attribute_list,
                line_break: line_break,
                source_line: SourceLineExtractor.extract(path)
              )
            end

            # Audio
            rule(
              audio: {
                path: simple(:path),
                attribute_list: simple(:attribute_list),
                line_break: simple(:line_break)
              }
            ) do
              Model::Audio.new(
                src: path.to_s,
                attributes: attribute_list,
                line_break: line_break,
                source_line: SourceLineExtractor.extract(path)
              )
            end

            # Video
            rule(
              video: {
                path: simple(:path),
                attribute_list: simple(:attribute_list),
                line_break: simple(:line_break)
              }
            ) do
              Model::Video.new(
                src: path.to_s,
                attributes: attribute_list,
                line_break: line_break,
                source_line: SourceLineExtractor.extract(path)
              )
            end

            # Reviewer Note
            rule(reviewer_note: subtree(:reviewer_note)) do
              reviewer_attributes_hash = reviewer_note[:reviewer_attributes]
              lines = reviewer_note[:lines] || []

              attrs = {}
              if reviewer_attributes_hash.is_a?(Model::AttributeList)
                reviewer_attributes_hash.named.each do |attr|
                  attrs[attr.name.to_sym] = attr.value.is_a?(Array) ? attr.value.first : attr.value
                end
              elsif reviewer_attributes_hash.is_a?(Hash) && reviewer_attributes_hash[:attribute_list]
                attr_list = Transformer.new.apply(reviewer_attributes_hash[:attribute_list])
                if attr_list.is_a?(Model::AttributeList)
                  attr_list.named.each do |attr|
                    attrs[attr.name.to_sym] = attr.value.is_a?(Array) ? attr.value.first : attr.value
                  end
                end
              end

              Model::ReviewerNote.new(
                reviewer: attrs[:reviewer],
                date: attrs[:date],
                from: attrs[:from],
                to: attrs[:to],
                content: Transformer.lines_to_text_elements(lines),
                source_line: SourceLineExtractor.extract(reviewer_note)
              )
            end
          end
        end
      end
    end
  end
end
