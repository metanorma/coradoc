module Coradoc
  module Parser
    module Asciidoc
      module AttributeList

        def named_attribute_name
          attribute_name
        end

        def named_attribute_value
          match('[^\],]').repeat(1)
        end

        def named_attribute
          (match['a-zA-Z0-9_-'].repeat(1).as(:named_key) >>
            space? >> str("=") >> space? >>
            match['a-zA-Z0-9_-'].repeat(1).as(:named_value) >>
            space?
            ).as(:named)
        end

        def positional_attribute
          (match['a-zA-Z0-9_-'].repeat(1) >>
            str("=").absent?
            ).as(:positional)
        end

        def attribute_list
          str("[") >>
          (
            (named_attribute.repeat(1,1) >>
              (str(",") >> named_attribute).repeat(0)) |
            (positional_attribute.repeat(1,1) >>
              (str(",") >> named_attribute).repeat(1)) |
            (positional_attribute.repeat(1,1) >>
              (str(",") >> positional_attribute).repeat(1) >>
              (str(",") >> named_attribute).repeat(1)) |
            (positional_attribute.repeat(1,1) >>
              (str(",") >> positional_attribute).repeat(0)) |
            positional_attribute.repeat(0,1)
            ).as(:attribute_array).as(:attribute_list) >>
          str("]")
        end

      end
    end
  end
end
