# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      module CodeBlock
        def self.source(element, context:)
          build_code_block(element, context, node_class: Node::CodeBlock)
        end

        def self.listing(element, context:)
          build_code_block(element, context, node_class: Node::CodeBlock)
        end

        def self.literal(element, context:)
          build_code_block(element, context, node_class: Node::LiteralBlock)
        end

        def self.pass(element, context:)
          build_code_block(element, context, node_class: Node::PassBlock, passthrough: true)
        end

        def self.stem(element, context:)
          build_code_block(element, context, node_class: Node::StemBlock)
        end

        class << self
          private

          def build_code_block(element, context, node_class:, passthrough: false)
            text = extract_text(element)
            js_mode = context.partition_structural
            attrs = Node::CodeBlock::Attrs.new(
              title: element.title,
              language: element.language,
              passthrough: passthrough || nil,
              text: js_mode ? text : nil
            )

            if js_mode
              node_class.new(attrs: attrs, content: [])
            else
              node_class.new(attrs: attrs, content: [context.text_node(text)])
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
