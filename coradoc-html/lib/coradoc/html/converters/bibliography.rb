# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for CoreModel::Block (bibliography) to HTML bibliography section
      class Bibliography < Base
        # Convert CoreModel::Block (bibliography) to HTML bibliography section
        def self.to_html(bibliography, _options = {})
          return '' unless bibliography

          # Build section attributes
          attrs = build_attributes(bibliography)

          # Build title
          title_html = build_title(bibliography)

          # Process bibliography entries (children)
          entries = bibliography.children || []
          entries_html = entries.map do |entry|
            BibliographyEntry.to_html(entry)
          end.join("\n")

          # Combine into bibliography section
          bib_html = ''
          bib_html += "#{title_html}\n" if title_html
          bib_html += %(<div class="bibliography-entries">\n#{entries_html}\n</div>) unless entries_html.empty?

          %(<section#{attrs}>\n#{bib_html}\n</section>)
        end

        # Convert HTML bibliography section to CoreModel::Block (bibliography)
        def self.to_coradoc(element, _options = {})
          return nil unless element.name == 'section'
          return nil unless element['class']&.include?('bibliography')

          # Extract title
          title_elem = element.at_css('h1, h2, h3, h4, h5, h6, .bibliography-title')
          title = title_elem&.text&.strip

          # Extract entries
          entries_container = element.at_css('.bibliography-entries')
          entries = if entries_container
                      entries_container.css('.bibliography-entry').map do |entry_elem|
                        BibliographyEntry.to_coradoc(entry_elem)
                      end.compact
                    else
                      []
                    end

          # Extract ID if present
          id = element['id']

          Coradoc::CoreModel::Block.new(
            element_type: 'bibliography',
            title: title,
            id: id,
            children: entries
          )
        end

        def self.build_attributes(bibliography)
          attrs = [%( class="bibliography")]

          # Add ID if present
          attrs << %( id="#{escape_attribute(bibliography.id)}") if bibliography.id

          attrs.join
        end

        def self.build_title(bibliography)
          return nil unless bibliography.title

          title_text = bibliography.title.to_s
          return nil if title_text.empty?

          %(<h2 class="bibliography-title">#{escape_html(title_text)}</h2>)
        end
      end
    end
  end
end
