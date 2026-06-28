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
              # Markdown fences carry the language tag inline (```ruby);
              # pass it through so the SourceCode classifier entry can set
              # block.lang directly, which extract_block_language prefers.
              opts[:lang] = block[:language].to_s if block.key?(:language) && !block[:language].nil?
              BlockTypeClassifier.classify(delimiter, opts, attribute_list)
            end

            # Example
            rule(example: sequence(:example)) do
              Model::Block::Example.new(
                title: '',
                lines: example
              )
            end

            # Admonition. Canonicalise the type to uppercase so round-trips
            # through HTML/Markdown/DocBook all see the same key used by
            # icon and CSS-class lookups.
            rule(
              admonition_type: simple(:admonition_type),
              content: sequence(:content)
            ) do
              canonical = Coradoc::AsciiDoc::Transform::ElementTransformers::AdmonitionStyles.canonicalize(admonition_type.to_s)
              Model::Admonition.new(
                content: content,
                type: canonical
              )
            end

            # Block image
            rule(block_image: subtree(:block_image)) do
              id = block_image[:id]
              title = block_image[:title]
              path = block_image[:path]
              attrs = AttributeListNormalizer.coerce(block_image[:attribute_list_macro])
              promoted, residual = Model::Image::AttributeExtractor.call(
                attrs, Model::Image::BlockImage
              )
              Model::Image::BlockImage.new(
                title: title,
                id: id,
                src: path,
                attributes: residual,
                line_break: "\n",
                **promoted
              )
            end
          end
        end
      end
    end
  end
end
