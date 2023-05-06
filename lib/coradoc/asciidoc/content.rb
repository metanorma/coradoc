module Coradoc
  module Asciidoc
    module Content
      include Coradoc::Asciidoc::Base

      def paragraph
        text_line.repeat(1)
      end

      def glossaries
        glossary.repeat(1)
      end

      # List
      def list
        unnumbered_list.as(:unnumbered) |
          definition_list.as(:definition) | numbered_list.as(:numbered)
      end

      def contents
        (
          list.as(:list) |
          table.as(:table) |
          highlight.as(:highlight) |
          glossaries.as(:glossaries) |
          paragraph.as(:paragraph) |
          empty_line.as(:line_break)
        ).repeat(1)
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

      # Extended
      def word
        (match("[a-zA-Z0-9_-]") | str(".") | str("*") | match("@")).repeat(1)
      end

      def empty_cell_content
        str("|").absent? >> literal_space.as(:text)
      end

      def cell_content
        str("|").absent? >> literal_space? >> words.as(:text)
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

      def glossary
        keyword.as(:key) >> str("::") >> space? >>
        text.as(:value) >> line_ending.as(:break)
      end

      def numbered_list
        nlist_item.repeat(1)
      end

      def unnumbered_list
        (ulist_item >> newline.maybe).repeat(1)
      end

      def definition_list
        dlist_item.repeat(1)
      end

      def nlist_item
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
