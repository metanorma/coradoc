# frozen_string_literal: true

require_relative 'base'

module Coradoc
  module Html
    module Converters
      # Converter for CoreModel::InlineElement (term) elements
      #
      # Terms are used in definition lists and can have types like "acronym",
      # "symbol", "preferred", etc.
      class Term < Base
        # Convert HTML to CoreModel::InlineElement (term)
        def self.to_coradoc(node, _state = {})
          attrs = extract_node_attributes(node)

          term_text = node.text.strip
          term_type = attrs[:'data-term-type'] || attrs[:class]&.split&.find do |c|
            c.start_with?('term-')
          end&.sub('term-', '')

          Coradoc::CoreModel::InlineElement.new(
            format_type: 'term',
            content: term_text,
            target: term_type || 'term',
            metadata: {
              lang: attrs[:lang] || 'en',
              render_text: attrs[:'data-render-text']
            }
          )
        end

        # Convert CoreModel::InlineElement (term) to HTML
        def self.to_html(term, _state = {})
          term_text = term.content || ''
          term_type = term.target || 'term'
          render_text = term.metadata&.dig(:render_text)

          # Use render_text if available, otherwise use term
          display_text = render_text&.strip&.empty? ? false : render_text
          display_text ||= term_text

          # Build class attribute
          classes = ['term', "term-#{escape_attribute(term_type)}"]
          class_attr = classes.join(' ')

          # Build data attributes
          data_attrs = []
          data_attrs << %( data-term-ref="#{escape_attribute(term_text)}")
          lang = term.metadata&.dig(:lang)
          data_attrs << %( lang="#{escape_attribute(lang)}") if lang && lang != 'en'

          # Render as a styled span with term reference
          %(<span class="#{class_attr}"#{data_attrs.join}>#{escape_html(display_text)}</span>)
        end
      end
    end
  end
end
