# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      module Blockquote
        def self.call(element, context:)
          content = context.extract_content(element)
          return nil if content.empty?

          Node::Blockquote.new(
            attrs: Node::Blockquote::Attrs.new(attribution: element.attribution),
            content: content
          )
        end
      end
    end
  end
end
