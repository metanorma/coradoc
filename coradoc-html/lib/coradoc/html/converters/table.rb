# frozen_string_literal: true

module Coradoc
  module Html
    module Converters
      class Table < Base
        # Convert CoreModel::Table to HTML <table>
        def self.to_html(table, _options = {})
          attrs = build_attributes(table)
          caption = build_caption(table)

          rows_html = table.rows.map do |row|
            TableRow.to_html(row)
          end.join("\n")

          table_content = rows_html
          table_content = "#{caption}\n#{table_content}" if caption

          "<table#{attrs}>\n#{table_content}\n</table>"
        end

        # Convert HTML <table> to CoreModel::Table
        def self.to_coradoc(element, _options = {})
          return nil unless element.name == 'table'

          rows = element.css('tr').map do |tr|
            TableRow.to_coradoc(tr)
          end.compact

          # Extract caption if present
          caption_elem = element.at_css('caption')
          title = caption_elem&.text&.strip

          # Extract table attributes
          attrs = extract_table_attributes(element)

          table = Coradoc::CoreModel::Table.new(
            rows: rows,
            title: title
          )
          table.id = attrs[:id] if attrs[:id]
          table.frame = attrs[:frame] if attrs[:frame]

          table
        end

        def self.build_attributes(table)
          attrs = []

          # Add ID if present
          attrs << %( id="#{escape_attribute(table.id)}") if table.respond_to?(:id) && table.id

          # CoreModel::Table with frame attribute
          attrs << %( class="frame-#{escape_attribute(table.frame)}") if table.respond_to?(:frame) && table.frame

          attrs.join
        end

        def self.build_caption(table)
          return nil unless table.respond_to?(:title) && table.title

          caption_text = table.title.to_s
          return nil if caption_text.empty?

          "<caption>#{escape_html(caption_text)}</caption>"
        end

        def self.extract_table_attributes(element)
          attrs = {}

          # Extract id attribute
          attrs[:id] = element['id'] if element['id']

          # Extract frame attribute from class
          if element['class']&.include?('frame-')
            frame = element['class'][/frame-(\w+)/, 1]
            attrs[:frame] = frame if frame
          end

          attrs
        end
      end
    end
  end
end
