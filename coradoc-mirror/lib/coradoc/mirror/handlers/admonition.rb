# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      # Admonition (NOTE, TIP, WARNING, CAUTION, IMPORTANT) handler.
      #
      # Emits a dialect-agnostic `Node::Admonition`. The canonical Ruby
      # attribute is `admonition_type`; the model renames it to the wire
      # name `type` on #to_h unconditionally. No flag, no dialect branch.
      module Admonition
        def self.call(element, context:)
          content = context.extract_content(element)
          return nil if content.empty?

          Node::Admonition.new(
            attrs: Node::Admonition::Attrs.new(
              admonition_type: element.annotation_type,
              title: element.title,
              label: element.annotation_label,
              id: element.id
            ),
            content: content
          )
        end
      end
    end
  end
end
