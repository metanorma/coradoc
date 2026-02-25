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
              attribute_list = block[:attribute_list]
              delimiter = block[:delimiter].to_s
              delimiter_c = delimiter[0]
              lines = block[:lines]
              ordering = block.keys.select do |k|
                %i[id title attribute_list attribute_list2].include?(k)
              end

              opts = {
                id: id,
                title: title,
                delimiter_len: delimiter.size,
                lines: lines,
                ordering: ordering
              }
              opts[:attributes] = attribute_list if attribute_list
              delimiter_len = opts[:delimiter_len]

              if delimiter_c == '*'
                if attribute_list
                  if attribute_list.positional == [] &&
                     attribute_list.named.first&.name == 'reviewer'
                    Model::Block::ReviewerComment.new(
                      id:,
                      title:,
                      lines:,
                      delimiter_len:,
                      attributes: attribute_list
                    )
                  else
                    Model::Block::Side.new(id:, title:, lines:, delimiter_len:,
                                           attributes: attribute_list)
                  end
                else
                  Model::Block::Side.new(id:, title:, lines:, delimiter_len:,
                                         attributes: attribute_list)
                end
              elsif delimiter_c == '='
                Model::Block::Example.new(id:, title:, lines:, delimiter_len:,
                                          attributes: attribute_list)
              elsif delimiter_c == '+'
                Model::Block::Pass.new(id:, title:, lines:, delimiter_len:,
                                       attributes: attribute_list)
              elsif delimiter_c == '-' && delimiter.size == 2
                Model::Block::Open.new(id:, title:, lines:, delimiter_len:,
                                       attributes: attribute_list)
              elsif delimiter_c == '-' && delimiter.size >= 4
                Model::Block::SourceCode.new(id:, title:, lines:, delimiter_len:,
                                             attributes: attribute_list)
              elsif delimiter_c == '_'
                Model::Block::Quote.new(id:, title:, lines:, delimiter_len:,
                                        attributes: attribute_list)
              end
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
              attrs = block_image[:attribute_list]
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
