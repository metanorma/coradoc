# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      module Partintro
        def self.call(element, context:)
          content = context.extract_content(element)
          return nil if content.empty?

          Node::Partintro.new(
            attrs: Node::Partintro::Attrs.new(id: element.id, title: element.title),
            content: content
          )
        end
      end
    end
  end
end
