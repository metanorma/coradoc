# frozen_string_literal: true

module Coradoc
  module Html
    # Serializes a document's TOC structure to JSON for inline embedding.
    #
    # Used by the SPA layout to provide client-side navigation data.
    class TocSerializer
      def build_json(document, options)
        return { entries: [], numbered: false } unless document.is_a?(CoreModel::StructuralElement)

        numbered = options[:sectnums] == true
        builder = TocBuilder.from_options(options)
        toc = builder.build(document)
        { entries: serialize_entries(toc.entries), numbered: numbered }
      end

      private

      def serialize_entries(entries)
        entries.map do |entry|
          {
            id: entry.id,
            title: TitleText.resolve(entry.title),
            number: entry.number,
            level: entry.level,
            children: entry.children.any? ? serialize_entries(entry.children) : []
          }
        end
      end
    end
  end
end
