module Coradoc
  module Parser
    module Asciidoc
      module Content
        include Coradoc::Parser::Asciidoc::Base

        def paragraph
          paragraph_meta.as(:meta).maybe >>
            text_line.repeat(1).as(:lines)
        end

        def glossaries
          glossary.repeat(1)
        end

        # List
        def list
          unordered_list.as(:unordered) |
            definition_list.as(:definition) | ordered_list.as(:ordered)
        end

        def contents
          (
            block.as(:block) |
            list.as(:list) |
            table.as(:table) |
            highlight.as(:highlight) |
            glossaries.as(:glossaries) |
            paragraph.as(:paragraph) | empty_line
          ).repeat(1)
        end

        def block
          sidebar_block | example_block | source_block | quote_block
        end

        def source_block
          block_style("-", 2)
        end

        def quote_block
          block_style("_")
        end

        def sidebar_block
          block_style("*")
        end

        def example_block
          block_style("=")
        end

        def block_style(delimiter="*", repeater = 4)
          block_title.maybe >>
          newline.maybe >>
          block_type.maybe >>
          str(delimiter).repeat(repeater).as(:delimiter) >> newline >>
          text_line.repeat(1).as(:lines) >>
          str(delimiter).repeat(repeater) >> newline
        end

        def block_type
          str("[") >> keyword.as(:type) >> str("]") >> newline
        end

        def highlight
          text_id >> newline >>
          underline >> highlight_text >> newline
        end

        def underline
          str("[underline]") | str("[.underline]")
        end

        def highlight_text
          str("#") >> words.as(:text) >> str("#")
        end

        # Table
        def table
          block_title >>
          str("|===") >> line_ending >>
          table_row.repeat(1).as(:rows) >>
          str("|===") >> line_ending
        end

        def table_row
          (literal_space? >> str("|") >> (cell_content | empty_cell_content)).
            repeat(1).as(:cols) >> line_ending
        end

        def empty_cell_content
          str("|").absent? >> literal_space.as(:text)
        end

        def cell_content
          str("|").absent? >> literal_space? >> rich_texts.as(:text)
        end

        def literal_space
          (match[' '] | match[' \t']).repeat(1)
        end

        # Override
        def literal_space?
          literal_space.maybe
        end

        def block_title
          str(".") >> text.as(:title) >> line_ending
        end

        # Text
        def text_line
          (asciidoc_char_with_id.absent? | text_id) >> literal_space? >>
          text.as(:text) >> line_ending.as(:break)
        end

        def asciidoc_char
          match("^[*_:=-]")
        end

        def asciidoc_char_with_id
          asciidoc_char | str("[#") | str("[[")
        end

        def text_id
          str("[[") >> keyword.as(:id) >> str("]]") |
            str("[#") >> keyword.as(:id) >> str("]")
        end

        def paragraph_meta
          str("[") >>
            keyword.as(:key) >> str("=") >>
            word.as(:value) >> str("]") >> newline
        end

        def glossary
          keyword.as(:key) >> str("::") >> space? >>
          text.as(:value) >> line_ending.as(:break)
        end

        def ordered_list
          olist_item.repeat(1)
        end

        def unordered_list
          (ulist_item >> newline.maybe).repeat(1)
        end

        def definition_list
          dlist_item.repeat(1)
        end

        def olist_item
          match("\.") >> space >> text_line
        end

        def ulist_item
          match("\\*") >> space >> text_line
        end

        def dlist_item
          str("term") >> space >> digits >> str("::") >> space >> text_line
        end
      end
    end
  end
end
