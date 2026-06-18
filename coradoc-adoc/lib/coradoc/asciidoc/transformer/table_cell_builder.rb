# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    class Transformer < Parslet::Transform
      # Pure functions for parsing the cell-format prefix (`2+^.^a`) and
      # building a Model::TableCell from raw parser values.
      #
      # Extracted from the Transformer god class. The format spec can come
      # in two shapes from the parser — a Hash of named captures or a raw
      # String from a capture group — and the layout/alignment/style parsing
      # for each used to be inline in Transformer#build_table_cell.
      module TableCellBuilder
        module_function

        # @param format [Hash, String, Object, nil] Cell format from parser
        # @param content [Object] Cell content
        # @return [Model::TableCell]
        def build(format, content)
          cell_opts = {}
          style = parse_format(format, cell_opts)

          unescaped_content = content.to_s.gsub(/\\([|!,:;])/, '\1')
          cell_opts[:content] = parse_inline_content(unescaped_content, style)

          Model::TableCell.new(**cell_opts)
        end

        # Coerce a raw parser cell value into a TableCell.
        # Used by TableLayout.group_cells_into_rows when it encounters
        # cells that the parser emitted as Hashes or plain strings.
        # @param cell [Model::TableCell, Hash, Object]
        # @return [Model::TableCell]
        def normalize_cell(cell)
          case cell
          when Model::TableCell then cell
          when Hash
            content = cell[:text] || cell[:content] || ''
            Model::TableCell.new(content: parse_inline_content(content))
          else
            Model::TableCell.new(content: parse_inline_content(cell))
          end
        end

        # Parse inline content from raw text for a cell.
        # @param text [String, nil]
        # @param style [String, nil] 'a' (AsciiDoc), 'l' (literal), or nil
        # @return [Array<Model::TextElement>]
        def parse_inline_content(text, style = nil)
          return [Model::TextElement.new(content: '')] if text.nil? || text.to_s.strip.empty?

          return parse_block_content(text) if style == 'a'
          return [Model::TextElement.new(content: text.to_s)] if style == 'l'

          parser = Coradoc::AsciiDoc::Parser::Base.new
          begin
            ast = parser.text_any.parse(text.to_s)
            transformed = Transformer.new.apply(ast)
            content_array = transformed.is_a?(Array) ? transformed : [transformed]
            [Model::TextElement.new(content: content_array)]
          rescue Parslet::ParseFailed
            [Model::TextElement.new(content: text.to_s)]
          end
        end

        # Parse block-level AsciiDoc content (for 'a' style cells).
        # @param text [String, nil]
        # @return [Array]
        def parse_block_content(text)
          return [Model::TextElement.new(content: '')] if text.nil? || text.to_s.strip.empty?

          parser = Coradoc::AsciiDoc::Parser::Base.new
          text_str = text.to_s

          if /^(\*+|-+|\d+\.)/m.match?(text_str)
            list_match = text_str.match(/\n(\*+|-+|\d+\.)(.*)$/m)
            if list_match
              list_text = list_match[1] + list_match[2]
              begin
                ast = parser.list.parse(list_text)
                transformed = Transformer.new.apply(ast)

                before_list = text_str[0, list_match.begin(1) - 1].strip
                before_elements = []
                unless before_list.empty?
                  begin
                    before_ast = parser.text_any.parse(before_list)
                    before_transformed = Transformer.new.apply(before_ast)
                    before_array = before_transformed.is_a?(Array) ? before_transformed : [before_transformed]
                    before_elements = [Model::TextElement.new(content: before_array)]
                  rescue Parslet::ParseFailed
                    before_elements = [Model::TextElement.new(content: before_list)]
                  end
                end

                return before_elements + [transformed]
              rescue Parslet::ParseFailed
                # fall through to inline parsing
              end
            end
          end

          begin
            ast = parser.text_any.parse(text_str)
            transformed = Transformer.new.apply(ast)
            content_array = transformed.is_a?(Array) ? transformed : [transformed]
            [Model::TextElement.new(content: content_array)]
          rescue Parslet::ParseFailed
            [Model::TextElement.new(content: text_str)]
          end
        end

        # Parse the cell-format prefix and populate cell_opts.
        # @param format [Hash, String, Object, nil]
        # @param cell_opts [Hash] Mutated in place
        # @return [String, nil] The parsed style character
        def parse_format(format, cell_opts)
          if format.is_a?(Hash)
            parse_format_hash(format, cell_opts)
          elsif format.is_a?(String)
            parse_format_string(format, cell_opts)
          end
        end

        def parse_format_hash(format, cell_opts)
          cell_opts[:colspan] = format[:colspan].to_i if format[:colspan]

          if format[:rowspan]
            rowspan_str = format[:rowspan].to_s.sub(/^\./, '')
            cell_opts[:rowspan] = rowspan_str.to_i if rowspan_str.match?(/^\d+$/)
          end

          cell_opts[:halign] = format[:halign].to_s if format[:halign]

          if format[:valign]
            valign_str = format[:valign].to_s.sub(/^\./, '')
            cell_opts[:valign] = valign_str if %w[< ^ >].include?(valign_str)
          end

          style = format[:style].to_s if format[:style]
          cell_opts[:style] = style
          cell_opts[:repeat] = true if format[:repeat]
          style
        end

        def parse_format_string(format_str, cell_opts)
          cell_opts[:colspan] = Regexp.last_match(1).to_i if format_str =~ /^(\d+)\+/
          cell_opts[:rowspan] = Regexp.last_match(1).to_i if format_str =~ /\.(\d+)/
          cell_opts[:halign] = Regexp.last_match(0) if format_str =~ /[<>^]/
          cell_opts[:valign] = Regexp.last_match(0)[1] if format_str =~ /\.[.^<>]/

          style = Regexp.last_match(0) if format_str =~ /[dsemalhv]/
          cell_opts[:style] = style

          cell_opts[:repeat] = true if format_str.include?('*')
          style
        end
      end
    end
  end
end
