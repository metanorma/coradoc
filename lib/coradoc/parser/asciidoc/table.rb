module Coradoc
  module Parser
    module Asciidoc
      module Table
        # include Coradoc::Parser::Asciidoc::Base

        def table
          element_id.maybe >>
          (attribute_list >> newline).maybe >>
          block_title.maybe >>
          (attribute_list >> newline).maybe >>
            str("|===") >> line_ending >>
            table_row.repeat(1).as(:rows) >>
            str("|===") >> line_ending
        end

        def table_row
          (literal_space? >> str("|") >> (cell_content | empty_cell_content))
            .repeat(1).as(:cols) >> line_ending
        end

        def empty_cell_content
          str("|").absent? >> literal_space.as(:text)
        end

        def cell_content
          str("|").absent? >> literal_space? >> rich_texts.as(:text)
        end
      end
    end
  end
end