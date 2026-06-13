# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      module Image
        def self.call(element, context:)
          Node::Image.new(
            id: element.id,
            src: element.src,
            alt: element.alt,
            title: element.title,
            caption: element.caption,
            width: element.width,
            height: element.height,
            inline: element.inline || nil,
          )
        end
      end
    end
  end
end
