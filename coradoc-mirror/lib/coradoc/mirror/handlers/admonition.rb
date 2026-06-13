# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      module Admonition
        def self.call(element, context:)
          content = context.extract_content(element)
          return nil if content.empty?

          Node::Admonition.new(
            id: element.id,
            admonition_type: element.annotation_type,
            title: element.title,
            label: element.annotation_label,
            content: content
          )
        end
      end
    end
  end
end
