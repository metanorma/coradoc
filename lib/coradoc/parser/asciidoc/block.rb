module Coradoc
  module Parser
    module Asciidoc
      module Block

        def block
          sidebar_block |
          example_block |
          source_block |
          quote_block
        end

        def source_block
          block_style("-", 2)
        end

        def source_block
          block_style("-", 2)
        end

        def quote_block
          block_style("_")
        end

        def block_content
          (text_line |
            list
          ).repeat(1) #>> newline
        end

        def sidebar_block
          block_style("*")
        end

        def example_block
          block_style("=")
        end

        def block_title
          str(".") >> space.absent? >> text.as(:title) >> newline
        end

        def block_type(type)
          (str("[") >> str(type).as(:type) >> str("]")) | 
            (str("[") >> keyword.as(:type) >> str("]")
          ) >> newline
        end

        def block_style(delimiter = "*", repeater = 4, type = "")
          block_title.maybe >>
            newline.maybe >>
            (attribute_list >> newline ).maybe >>
            str(delimiter).repeat(repeater).as(:delimiter) >> newline >>
            block_content.as(:lines) >>
            str(delimiter).repeat(repeater) >> newline
        end

      end
    end
  end
end
