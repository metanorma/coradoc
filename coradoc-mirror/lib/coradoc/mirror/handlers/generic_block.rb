# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      module GenericBlock
        def self.call(element, context:)
          semantic_type = element.resolve_semantic_type
          content = context.extract_content(element)
          return nil if content.empty?

          Node::GenericBlock.new(
            id: element.id,
            title: element.title,
            semantic_type: semantic_type&.to_s,
            content: content,
          )
        end
      end
    end
  end
end
