# frozen_string_literal: true

module Coradoc
  module Mirror
    module Handlers
      module Bibliography
        def self.call(element, context:)
          entries = Array(element.entries).filter_map do |entry|
            build_entry(entry, context)
          end
          return nil if entries.empty?

          Node::Bibliography.new(
            id: element.id,
            title: element.title,
            level: element.level,
            content: entries
          )
        end

        class << self
          private

          def build_entry(entry, context)
            text = entry.display_text
            return nil if text.nil? || text.empty?

            Node::BibliographyEntry.new(
              anchor_name: entry.anchor_name,
              document_id: entry.document_id,
              url: entry.url,
              content: [context.text_node(text)]
            )
          end
        end
      end
    end
  end
end
