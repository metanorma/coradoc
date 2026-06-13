# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      module Structural
        def self.document(element, context:)
          content = context.extract_content(element)
          Node::Document.new(
            title: element.title,
            id: element.id,
            content: content
          )
        end

        def self.section(element, context:)
          content = context.extract_content(element)
          Node::Section.new(
            id: element.id,
            title: element.title,
            level: element.heading_level,
            content: content
          )
        end

        def self.preamble(element, context:)
          content = context.extract_content(element)
          Node::Preamble.new(content: content)
        end

        def self.header(element, context:)
          content = context.extract_content(element)
          Node::Header.new(
            title: element.title,
            level: element.heading_level,
            content: content
          )
        end
      end
    end
  end
end
