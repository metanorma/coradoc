# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Verse < Base
        def self.to_html(verse, _options = {})
          return '' unless verse

          attrs = { class: 'verse' }
          attrs[:id] = verse.id if verse.id

          children = []

          children << NodeBuilder.build(:div, escape_html(verse.title.to_s), class: 'verse-title') if verse.title && !verse.title.to_s.empty?

          content = process_content(verse.content)
          children << NodeBuilder.build(:pre, content, class: 'verse-content')

          attribution = build_attribution(verse)
          children << NodeBuilder.build(:fragment, attribution) if attribution

          NodeBuilder.build(:div, children, **attrs).to_html
        end

        def self.to_coradoc(element, _options = {})
          return nil unless element.name == 'div'
          return nil unless element['class']&.include?('verse')

          title_elem = element.at_css('.verse-title')
          title = title_elem&.text&.strip

          content_elem = element.at_css('.verse-content, pre')
          content = content_elem&.text || ''

          cite_elem = element.at_css('cite, footer')
          attribution = cite_elem&.text&.strip

          Coradoc::CoreModel::VerseBlock.new(
            content: content,
            title: title,
            id: element['id'],
            attribution: attribution
          )
        end

        def self.build_attribution(verse)
          attribution_text = verse.metadata&.dig(:attribution)
          return nil unless attribution_text
          return nil if attribution_text.to_s.strip.empty?

          NodeBuilder.build(:footer, escape_html(attribution_text.to_s.strip)).to_html
        end

        def self.process_content(content)
          return '' if content.nil?

          if content.is_a?(String)
            escape_html(content)
          elsif content.is_a?(Array)
            content.map { |line| escape_html(line.to_s) }.join("\n")
          else
            escape_html(content.to_s)
          end
        end
      end
    end
  end
end
