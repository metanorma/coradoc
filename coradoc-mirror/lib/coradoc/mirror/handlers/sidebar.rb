# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      module Sidebar
        def self.call(element, context:)
          content = context.extract_content(element)
          return nil if content.empty?

          Node::Sidebar.new(
            attrs: Node::Sidebar::Attrs.new(id: element.id, title: element.title),
            content: content
          )
        end
      end
    end
  end
end
