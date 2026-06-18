# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    class Transformer < Parslet::Transform
      # Module containing block element transformation rules
      module BlockRules
        def self.apply(transformer_class)
          transformer_class.class_eval do
            # Generic block
            rule(block: subtree(:block)) do
              id = block[:id]
              title = block[:title]
              attribute_list = AttributeListNormalizer.coerce(block[:attribute_list])
              delimiter = block[:delimiter].to_s
              lines = block[:lines]
              ordering = block.keys.select do |k|
                %i[id title attribute_list].include?(k)
              end

              opts = {
                id: id,
                title: title,
                delimiter_len: delimiter.size,
                lines: lines,
                ordering: ordering
              }
              BlockTypeClassifier.classify(delimiter, opts, attribute_list)
            end

            # Example
            rule(example: sequence(:example)) do
              Model::Block::Example.new(title: '', lines: example)
            end

            # Admonition
            rule(
              admonition_type: simple(:admonition_type),
              content: sequence(:content)
            ) do
              Model::Admonition.new(content: content, type: admonition_type.to_s)
            end

            # Block image
            rule(block_image: subtree(:block_image)) do
              id = block_image[:id]
              title = block_image[:title]
              path = block_image[:path]
              attrs = AttributeListNormalizer.coerce(block_image[:attribute_list])
              Model::Image::BlockImage.new(
                title: title,
                id: id,
                src: path,
                attributes: attrs,
                line_break: "\n"
              )
            end
          end
        end
      end
    end
  end
end
