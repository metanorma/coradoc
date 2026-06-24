# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      module CodeBlock
        def self.source(element, context:)
          build_code_block(element, context)
        end

        def self.listing(element, context:)
          build_code_block(element, context)
        end

        def self.literal(element, context:)
          build_code_block(element, context)
        end

        def self.pass(element, context:)
          build_code_block(element, context, passthrough: true)
        end

        class << self
          private

          def build_code_block(element, context, passthrough: false)
            text = extract_text(element)
            js_mode = context.partition_structural

            if js_mode
              # @metanorma/mirror JS sourcecode contract: text in attrs.text,
              # no children. Pre-formatted text rendered via <pre><code>.
              Node::CodeBlock.new(
                attrs: Node::CodeBlock::Attrs.new(
                  title: element.title,
                  language: element.language,
                  passthrough: passthrough || nil,
                  text: text
                ),
                content: []
              )
            else
              Node::CodeBlock.new(
                attrs: Node::CodeBlock::Attrs.new(
                  title: element.title,
                  language: element.language,
                  passthrough: passthrough || nil
                ),
                content: [context.text_node(text)]
              )
            end
          end

          def extract_text(element)
            return '' unless element.is_a?(CoreModel::Block)

            if element.content && !element.content.to_s.empty?
              element.flat_text || element.content.to_s
            elsif element.lines && !element.lines.empty?
              Array(element.lines).join("\n")
            else
              ''
            end
          end
        end
      end
    end
  end
end
