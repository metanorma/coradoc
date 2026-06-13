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
            Node::CodeBlock.new(
              id: element.id,
              title: element.title,
              language: element.language,
              passthrough: passthrough || nil,
              content: [context.text_node(text)]
            )
          end

          def extract_text(element)
            if element.is_a?(CoreModel::Block) && element.content && !element.content.to_s.empty?
              element.flat_text || element.content.to_s
            elsif element.is_a?(CoreModel::Block) && element.lines && !element.lines.empty?
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
