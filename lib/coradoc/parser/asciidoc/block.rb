module Coradoc
  module Parser
    module Asciidoc
      module Block

        def block
          sidebar_block |
          example_block |
          source_block |
          quote_block |
          pass_block
        end

        def source_block
          block_style("-", 2)
        end

        def pass_block
          block_style("+", 4, :pass)
        end

        def source_block
          block_style("-", 2)
        end

        def quote_block
          block_style("_")
        end

        def block_content(n_deep = 2)
          c = block_image |
            list |
            text_line |
            empty_line.as(:line_break)
          c = c | block_content(n_deep - 1) if (n_deep > 0)
          c.repeat(1) #>> newline
        end

        def sidebar_block
          block_style("*")
        end

        def example_block
          block_style("=")
        end

        def block_title
          match("^\\.") >> space.absent? >> text.as(:title) >> newline
        end

        def block_type(type)
          (match('^\[') >> str("[").absent? >>
            str(type).as(:type) >>
            str("]")) | 
          (match('^\[') >> keyword.as(:type) >> str("]")) >> newline
        end

        def block_id
          (match('^\[') >> str("[") >> str('[').absent? >> keyword.as(:id) >> str("]]") |
            str("[#") >> keyword.as(:id) >> str("]")) >> newline
        end


        def block_style(delimiter = "*", repeater = 4, type = nil)
          block_id.maybe >>
          block_title.maybe >>
            newline.maybe >>
            (attribute_list >> newline ).maybe >>
            block_id.maybe >>
            (attribute_list >> newline ).maybe >>
            str(delimiter).repeat(repeater).as(:delimiter) >> newline >>
            if type == :pass
              (text_line | empty_line.as(:line_break)).repeat(1).as(:lines)
            else
              block_content.as(:lines)
            end >>
            str(delimiter).repeat(repeater) >> newline
        end

      end
    end
  end
end
