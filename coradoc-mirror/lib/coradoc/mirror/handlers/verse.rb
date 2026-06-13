# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      module Verse
        def self.call(element, context:)
          text = if element.content && !element.content.to_s.empty?
                   element.flat_text || element.content.to_s
                 else
                   ""
                 end

          Node::Verse.new(
            attribution: element.attribution,
            content: [context.text_node(text)],
          )
        end
      end
    end
  end
end
