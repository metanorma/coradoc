# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      module Paragraph
        def self.call(element, context:)
          content = context.process_inline_content(element)
          return nil if content.empty?

          Node::Paragraph.new(content: content)
        end
      end
    end
  end
end
