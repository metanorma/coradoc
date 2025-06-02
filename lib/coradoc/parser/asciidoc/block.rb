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
          str(".") >> space.absent? >> text.as(:title) >> newline
        end

        def block_type(type)
          (line_start? >> str("[") >> str("[").absent? >>
            str(type).as(:type) >>
            str("]")) >> newline # |
        end

        def block_content(n_deep = 3)
          c = block_image |
            audio |
            video |
            list |
            text_line |
            empty_line.as(:line_break)
          c = c | block(n_deep - 1) if n_deep.positive?
          c.repeat(1)
        end

        def block_delimiter
          line_start? >>
            ((str("*") | str("=") | str("_") | str("+") | str("-")).repeat(4) |
              str("-").repeat(2, 2)) >>
            newline
        end

        def element_attributes
          block_title.maybe >>
            element_id.maybe >>
            (attribute_list >> newline).maybe >>
            block_title.maybe >>
            newline.maybe >>
            (attribute_list >> newline).maybe >>
            element_id.maybe
        end

        def block_style(n_deep = 3, delimiter = "*", repeater = 4, type = nil)
          current_delimiter = str(delimiter).repeat(repeater).capture(:delimit)
          closing_delimiter = dynamic { |_s, c|
            str(c.captures[:delimit].to_s.strip)
          }

          element_attributes >>
            (line_start? >> attribute_list >> newline).maybe >>
            line_start? >>
            current_delimiter.as(:delimiter) >> newline >>
            if type == :pass
              (text_line | empty_line.as(:line_break)).repeat(1).as(:lines)
            else
              (closing_delimiter >> newline).absent? >> block_content(n_deep - 1).as(:lines)
            end >>
            line_start? >>
            closing_delimiter >> newline
        end
      end
    end
  end
end
