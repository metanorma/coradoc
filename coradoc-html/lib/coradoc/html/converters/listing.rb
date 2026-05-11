# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Listing < Base
        def self.to_html(listing, _options = {})
          return '' unless listing

          attrs = { class: 'listing' }
          attrs[:id] = listing.id if listing.id

          content = process_content(listing.content)
          pre_node = NodeBuilder.build(:pre, content, **attrs)

          if listing.title && !listing.title.to_s.empty?
            title_node = NodeBuilder.build(:div, escape_html(listing.title.to_s), class: 'listing-title')
            NodeBuilder.build(:div, [title_node, pre_node], class: 'listing-block').to_html
          else
            pre_node.to_html
          end
        end

        def self.to_coradoc(element, _options = {})
          pre_elem = if element.name == 'div' && element['class']&.include?('listing-block')
                       element.at_css('pre')
                     elsif element.name == 'pre'
                       element
                     else
                       return nil
                     end

          return nil unless pre_elem

          title = if element.name == 'div'
                    title_elem = element.at_css('.listing-title')
                    title_elem&.text&.strip
                  end

          content = pre_elem.text
          id = pre_elem['id'] || element['id']

          Coradoc::CoreModel::SourceBlock.new(
            content: content,
            title: title,
            id: id
          )
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
