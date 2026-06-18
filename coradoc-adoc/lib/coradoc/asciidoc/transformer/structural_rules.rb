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

            # Unified Table rule. Every variant (with or without title, id,
            # attributes) flows through here. Parser::BlockHeader always
            # captures attribute_lists as a sequence, so we funnel through
            # coerce_attribute_list before constructing the model.
            rule(table: subtree(:table)) do
              id = table[:id]&.to_s
              title = table[:title]&.to_s
              attrs = AttributeListNormalizer.coerce(table[:attribute_list])
              rows = table[:rows]
              opts = { rows: Transformer.regroup_table_rows(rows, attrs), attrs: attrs }
              opts[:id] = id if id
              opts[:title] = title unless title.nil? || title.empty?
              Model::Table.new(**opts)
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

              id = title.id if title.is_a?(Model::Title) && title.id && !id

              attribute_list = AttributeListNormalizer.coerce(section[:attribute_list])
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
              Model::BibliographyEntry.new(
                anchor_name: bib_entry[:anchor_name],
                document_id: bib_entry[:document_id],
                ref_text: Model::BibliographyEntry.coerce_ref_text(bib_entry[:ref_text]),
                line_break: bib_entry[:line_break]
              )
            end
          end
        end
      end
    end
  end
end
