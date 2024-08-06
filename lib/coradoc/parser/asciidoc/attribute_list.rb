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
          (match('[a-zA-Z0-9_-]').repeat(1).as(:named_key) >>
            str(' ').maybe >> str("=") >> str(' ').maybe >>
            match['a-zA-Z0-9_\- '].repeat(1).as(:named_value) >>
            str(' ').maybe
            ).as(:named)
        end

        def positional_attribute
          (match['a-zA-Z0-9_-'].repeat(1) >>
            str("=").absent?
            ).as(:positional)
        end

        def named_many
          (named_attribute.repeat(1,1) >>
              (str(",") >> named_attribute).repeat(0))
        end

        def positional_one_named_many
          (positional_attribute.repeat(1,1) >>
            (str(",") >> named_attribute).repeat(1))
        end

        def positional_many_named_many
          (positional_attribute.repeat(1,1) >>
            (str(",") >> positional_attribute).repeat(1) >>
            (str(",") >> named_attribute).repeat(1))
        end

        def positional_many
          (positional_attribute.repeat(1,1) >>
            (str(",") >> positional_attribute).repeat(0))
        end

        def positional_zero_or_one
          positional_attribute.repeat(0,1)
        end

        def attribute_list
          match('^\[') >> str("[").absent? >> 
          ( named_many |
            positional_one_named_many |
            positional_many_named_many |
            positional_many |
            positional_zero_or_one
          ).as(:attribute_array).as(:attribute_list) >>
          str("]")
        end

      end
    end
  end
end
