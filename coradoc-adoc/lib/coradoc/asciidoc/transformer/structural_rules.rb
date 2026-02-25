# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    class Transformer < Parslet::Transform
      # Module containing table and structural element transformation rules
      module StructuralRules
        def self.apply(transformer_class)
          transformer_class.class_eval do
            # Table cell with format specification
            rule(cell_format: simple(:format), text: simple(:text)) do
              Transformer.build_table_cell(format, text)
            end

            rule(cell_format: simple(:format), text: sequence(:text)) do
              Transformer.build_table_cell(format, text)
            end

            rule(cell_format: subtree(:format), text: simple(:text)) do
              Transformer.build_table_cell(format, text)
            end

            rule(cell_format: subtree(:format), text: sequence(:text)) do
              Transformer.build_table_cell(format, text)
            end

            # Table cell without format specification (plain content)
            # NOTE: These rules should ONLY match within table context
            # The generic text rules are handled by text_rules.rb
            # rule(text: simple(:text)) do
            #   Model::TableCell.new(content: text.to_s)
            # end
            #
            # rule(text: sequence(:text)) do
            #   Model::TableCell.new(content: text.map(&:to_s).join)
            # end

            # Single cell in a sequence - unwrap to TableCell
            rule(cell: simple(:cell)) do
              cell
            end

            # Unwrap single row
            rule(row: simple(:row)) do
              row
            end

            # Table row with cells
            rule(cells: sequence(:cells)) do
              Model::TableRow.new(columns: cells)
            end

            # Passthrough for attribute_list containing transformed attribute_array
            rule(attribute_list: { attribute_array: simple(:attrs) }) do
              attrs
            end

            # Passthrough for already-transformed Table
            rule(table: simple(:table)) do
              table
            end

            # Table with rows (new parser output - rows captured explicitly)
            rule(
              delim_char: simple(:delim_char),
              rows: sequence(:rows)
            ) do
              Model::Table.new(rows: rows)
            end

            # Table with rows and title
            rule(
              title: simple(:title),
              delim_char: simple(:delim_char),
              rows: sequence(:rows)
            ) do
              Model::Table.new(title: title.to_s, rows: rows)
            end

            # Table with rows and id
            rule(
              id: simple(:id),
              delim_char: simple(:delim_char),
              rows: sequence(:rows)
            ) do
              Model::Table.new(id: id.to_s, rows: rows)
            end

            # Table with rows, id, and attributes
            rule(
              id: simple(:id),
              attribute_list: simple(:attrs),
              delim_char: simple(:delim_char),
              rows: sequence(:rows)
            ) do
              Model::Table.new(id: id.to_s, rows: rows, attrs: attrs)
            end

            # Table with rows, title, and attributes
            rule(
              title: simple(:title),
              attribute_list: simple(:attrs),
              delim_char: simple(:delim_char),
              rows: sequence(:rows)
            ) do
              Model::Table.new(title: title.to_s, rows: rows, attrs: attrs)
            end

            # Table with rows and attributes only
            rule(
              attribute_list: simple(:attrs),
              delim_char: simple(:delim_char),
              rows: sequence(:rows)
            ) do
              Model::Table.new(rows: rows, attrs: attrs)
            end

            # Table with rows, id, title, and attributes (full set)
            rule(
              id: simple(:id),
              title: simple(:title),
              attribute_list: simple(:attrs),
              delim_char: simple(:delim_char),
              rows: sequence(:rows)
            ) do
              Model::Table.new(id: id.to_s, title: title.to_s, rows: rows, attrs: attrs)
            end

            # Table with id and title (no attributes)
            rule(
              id: simple(:id),
              title: simple(:title),
              delim_char: simple(:delim_char),
              rows: sequence(:rows)
            ) do
              Model::Table.new(id: id.to_s, title: title.to_s, rows: rows)
            end

            # Title
            rule(
              level: simple(:level),
              text: simple(:text),
              line_break: simple(:line_break)
            ) do
              Model::Title.new(
                content: text,
                level_int: level.size - 1,
                line_break: line_break
              )
            end

            rule(
              name: simple(:name),
              level: simple(:level),
              text: simple(:text),
              line_break: simple(:line_break)
            ) do
              Model::Title.new(
                content: text,
                level_int: level.size - 1,
                line_break: line_break,
                id: name
              )
            end

            # Section
            rule(section: subtree(:section)) do
              id = section[:id] || nil
              title = section[:title] || nil

              id = title.id if title.respond_to?(:id) && title.id && !id

              attribute_list = section[:attribute_list] || nil
              contents = section[:contents] || []
              sections = section[:sections]
              Model::Section.new(
                title: title,
                id: id,
                attribute_list: attribute_list,
                contents: contents,
                sections: sections
              )
            end

            rule(section: simple(:section)) do
              section
            end

            # Document
            rule(document: subtree(:document)) do
              elements = document.is_a?(Array) ? document : [document]
              Coradoc::AsciiDoc::Model::Document.from_ast(elements)
            end

            # Glossaries
            rule(glossaries: sequence(:glossaries)) do
              Model::Glossaries.new(items: glossaries)
            end

            # Bibliography entry
            rule(bibliography_entry: subtree(:bib_entry)) do
              anchor_name = bib_entry[:anchor_name]
              document_id = bib_entry[:document_id]
              ref_text = bib_entry[:ref_text]
              line_break = bib_entry[:line_break]
              Model::BibliographyEntry.new(
                anchor_name:, document_id:, ref_text:, line_break:
              )
            end
          end
        end
      end
    end
  end
end
