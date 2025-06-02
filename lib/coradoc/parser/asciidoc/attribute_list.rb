module Coradoc
  module Parser
    module Asciidoc
      module AttributeList
        def named_attribute_name
          attribute_name
        end

        def named_value_noquote
          match('[^\],]').repeat(1)
        end

        def named_value_single_quote
          str("'") >> match("[^']").repeat(1) >> str("'")
        end

        def named_value_double_quote
          str('"') >> match('[^"]').repeat(1) >> str('"')
        end

        def named_value
          (named_value_single_quote |
            named_value_double_quote |
            named_value_noquote
          ).as(:named_value)
        end

        def named_key
          match("[a-zA-Z0-9_-]").repeat(1).as(:named_key)
        end

        def named_attribute
          (named_key >>
            str(" ").maybe >> str("=") >> str(" ").maybe >>
              named_value >>
              str(" ").maybe
          ).as(:named)
        end

        def positional_attribute
          (match['a-zA-Z0-9_\-%.'].repeat(1) >> str("=").absent?
          ).as(:positional)
        end

        def named_many
          (named_attribute.repeat(1, 1) >>
              (str(",") >> space.maybe >> named_attribute).repeat(0))
        end

        def positional_one_named_many
          (positional_attribute.repeat(1, 1) >>
            (str(",") >> space.maybe >> named_attribute).repeat(1))
        end

        def positional_many_named_many
          (positional_attribute.repeat(1, 1) >>
            (str(",") >> space.maybe >> positional_attribute).repeat(1) >>
            (str(",") >> space.maybe >> named_attribute).repeat(1))
        end

        def positional_many
          (positional_attribute.repeat(1, 1) >>
            (str(",") >> space.maybe >> positional_attribute).repeat(0))
        end

        def positional_zero_or_one
          positional_attribute.repeat(0, 1)
        end

        def attribute_list(name = :attribute_list)
          str("[").present? >>
            str("[") >> str("[").absent? >>
            (named_many |
              positional_one_named_many |
              positional_many_named_many |
              positional_many |
              positional_zero_or_one
            ).as(:attribute_array).as(name) >>
            str("]")
        end
      end
    end
  end
end
