# frozen_string_literal: true

require 'coradoc/html/node_builder'

module Coradoc
  module Html
    module Converters
      class Table < Base
        # Convert CoreModel::Table to HTML <table>
        def self.to_html(table, _options = {})
          rows_html = table.rows.map do |row|
            TableRow.to_html(row)
          end.join("\n")

          children = []
          if table.title && !table.title.to_s.empty?
            children << NodeBuilder.build(:caption,
                                          escape_html(table.title.to_s))
          end
          children << rows_html unless rows_html.empty?

          attrs = {}
          attrs[:id] = table.id if table.id
          attrs[:class] = "frame-#{table.frame}" if table.frame

          NodeBuilder.build(:table, children, **attrs).to_html
        end

        # Convert HTML <table> to CoreModel::Table
        def self.to_coradoc(element, _options = {})
          return nil unless element.name == 'table'

          rows = element.css('tr').map do |tr|
            TableRow.to_coradoc(tr)
          end.compact

          caption_elem = element.at_css('caption')
          title = caption_elem&.text&.strip

          attrs = extract_table_attributes(element)

          table = Coradoc::CoreModel::Table.new(
            rows: rows,
            title: title
          )
          table.id = attrs[:id] if attrs[:id]
          table.frame = attrs[:frame] if attrs[:frame]

          table
        end

        def self.extract_table_attributes(element)
          attrs = {}
          attrs[:id] = element['id'] if element['id']

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
