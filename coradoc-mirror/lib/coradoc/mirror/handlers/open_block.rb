# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      module OpenBlock
        def self.call(element, context:)
          content = context.extract_content(element)
          return nil if content.empty?

          Node::OpenBlock.new(content: content)
        end
      end
    end
  end
end
