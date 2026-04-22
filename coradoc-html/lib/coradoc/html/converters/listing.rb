# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      # Converter for CoreModel::Block (listing) to HTML <pre>
      class Listing < Base
        # Convert CoreModel::Block (listing) to HTML <pre>
        def self.to_html(listing, _options = {})
          return '' unless listing

          # Build pre attributes
          attrs = build_attributes(listing)

          # Build title if present
          title_html = build_title(listing)

          # Process listing content - preserve formatting
          content = process_content(listing.content)

          # Combine title and content
          listing_html = ''
          listing_html += "#{title_html}\n" if title_html
          listing_html += %(<pre#{attrs}>#{content}</pre>)

          if title_html
            %(<div class="listing-block">\n#{listing_html}\n</div>)
          else
            listing_html
          end
        end

        # Convert HTML <pre> to CoreModel::Block (listing)
        def self.to_coradoc(element, _options = {})
          # Handle both <pre> and <div class="listing-block"><pre>
          pre_elem = if element.name == 'div' && element['class']&.include?('listing-block')
                       element.at_css('pre')
                     elsif element.name == 'pre'
                       element
                     else
                       return nil
                     end

          return nil unless pre_elem

          # Extract title if in listing-block wrapper
          title = if element.name == 'div'
                    title_elem = element.at_css('.listing-title')
                    title_elem&.text&.strip
                  end

          # Extract content
          content = pre_elem.text

          # Extract ID if present
          id = pre_elem['id'] || element['id']

          Coradoc::CoreModel::Block.new(
            delimiter_type: '----',
            content: content,
            title: title,
            id: id
          )
        end

        def self.build_attributes(listing)
          attrs = [%( class="listing")]

          # Add ID if present
          attrs << %( id="#{escape_attribute(listing.id)}") if listing.id

          attrs.join
        end

        def self.build_title(listing)
          return nil unless listing.title

          title_text = listing.title.to_s
          return nil if title_text.empty?

          %(<div class="listing-title">#{escape_html(title_text)}</div>)
        end

        def self.process_content(content)
          return '' if content.nil?

          # For listing, preserve the content as-is
          if content.is_a?(String)
            escape_html(content)
          elsif content.is_a?(Array)
            # Join array items with newlines
            content.map { |line| escape_html(line.to_s) }.join("\n")
          else
            escape_html(content.to_s)
          end
        end
      end
    end
  end
end
