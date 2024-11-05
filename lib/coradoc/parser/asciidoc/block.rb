module Coradoc
  module Parser
    module Asciidoc
      module Block

        def block(n_deep = 3)
          (example_block(n_deep) |
          sidebar_block(n_deep) |
          source_block(n_deep) |
          quote_block(n_deep) |
          pass_block(n_deep)).as(:block)
        end

        def example_block(n_deep)
          block_style(n_deep, "=")
        end

        def pass_block(n_deep)
          block_style(n_deep, "+", 4, :pass)
        end

        def quote_block(n_deep)
          block_style(n_deep, "_")
        end

        def sidebar_block(n_deep)
          block_style(n_deep, "*")
        end

        def source_block(n_deep)
          block_style(n_deep, "-", 2)
        end

        def block_title
          str('.') >> space.absent? >> text.as(:title) >> newline
        end

        def block_type(type)
          (str("[") >> str("[").absent? >>
            str(type).as(:type) >>
            str("]")) | 
          (match('^\[') >> keyword.as(:type) >> str("]")) >> newline
        end

        def block_id
          line_start? >>
          (str("[[") >> str('[').absent? >> keyword.as(:id) >> str("]]") |
            str("[#") >> keyword.as(:id) >> str("]")) >> newline
        end

        def block_content(n_deep = 3)
          c = block_image |
            list |
            text_line |
            empty_line.as(:line_break)
          c = c | block(n_deep - 1) if (n_deep > 0)
          c.repeat(1)
        end

        def block_delimiter
          line_start? >> 
          ((str("*") |
            str("=") |
            str("_") |
            str("+") |
            str("-")).repeat(4) |
            str("-").repeat(2,2)) >>
            newline
        end

        def block_style(n_deep = 3, delimiter = "*", repeater = 4, type = nil)
          block_title.maybe >>
          block_id.maybe >>
            (attribute_list >> newline ).maybe >>
          block_title.maybe >>
            newline.maybe >>
            (line_start? >> str('[').present? >> attribute_list >> newline ).maybe >>
            block_id.maybe >>
            (str('[').present? >> attribute_list >> newline ).maybe >>
            line_start? >>
            str(delimiter).repeat(repeater).capture(:delimit).as(:delimiter) >> newline >>
            if type == :pass
              (text_line | empty_line.as(:line_break)).repeat(1).as(:lines)
            else
              block_delimiter.absent? >> block_content(n_deep-1).as(:lines)
            end >>
            line_start? >>
            dynamic { |s,c| str(c.captures[:delimit].to_s.strip) } >> newline
            # str(delimiter).repeat(repeater) >> str(delimiter).absent? >> newline
        end

      end
    end
  end
end
