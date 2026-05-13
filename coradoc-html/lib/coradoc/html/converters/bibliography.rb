# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Bibliography < Base
        def self.to_html(bibliography, _options = {})
          return '' unless bibliography

          attrs = { class: 'bibliography' }
          attrs[:id] = bibliography.id if bibliography.id

          children = []

          if bibliography.title && !bibliography.title.to_s.empty?
            children << NodeBuilder.build(:h2, escape_html(bibliography.title.to_s),
                                          class: 'bibliography-title')
          end

          entries = bibliography.children || []
          entries_html = entries.map do |entry|
            BibliographyEntry.to_html(entry)
          end.join("\n")

          children << NodeBuilder.build(:div, entries_html, class: 'bibliography-entries') unless entries_html.empty?

          NodeBuilder.build(:section, children, **attrs).to_html
        end

        def self.to_coradoc(element, _options = {})
          return nil unless element.name == 'section'
          return nil unless element['class']&.include?('bibliography')

          title_elem = element.at_css('h1, h2, h3, h4, h5, h6, .bibliography-title')
          title = title_elem&.text&.strip

          entries_container = element.at_css('.bibliography-entries')
          entries = if entries_container
                      entries_container.css('.bibliography-entry').map do |entry_elem|
                        BibliographyEntry.to_coradoc(entry_elem)
                      end.compact
                    else
                      []
                    end

          Coradoc::CoreModel::Block.new(
            block_semantic_type: 'bibliography',
            title: title,
            id: element['id'],
            children: entries
          )
        end
      end
    end
  end
end
