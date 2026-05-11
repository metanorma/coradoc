# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      autoload :Base, "#{__dir__}/base"

      class Term < Base
        def self.to_coradoc(node, _state = {})
          attrs = extract_node_attributes(node)

          term_text = node.text.strip
          term_type = attrs[:'data-term-type'] || attrs[:class]&.split&.find do |c|
            c.start_with?('term-')
          end&.sub('term-', '')

          Coradoc::CoreModel::TermElement.new(
            content: term_text,
            target: term_type || 'term',
            metadata: {
              lang: attrs[:lang] || 'en',
              render_text: attrs[:'data-render-text']
            }
          )
        end

        def self.to_html(term, _state = {})
          term_text = term.content || ''
          term_type = term.target || 'term'
          render_text = term.metadata&.dig(:render_text)

          display_text = render_text&.strip&.empty? ? false : render_text
          display_text ||= term_text

          classes = "term term-#{term_type}"
          node = NodeBuilder.build(:span, escape_html(display_text), class: classes)
          node['data-term-ref'] = term_text.to_s

          lang = term.metadata&.dig(:lang)
          node['lang'] = lang if lang && lang != 'en'

          node.to_html
        end
      end
    end
  end
end
