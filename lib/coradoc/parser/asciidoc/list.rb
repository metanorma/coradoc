module Coradoc
  module Parser
    module Asciidoc
      module List

        def list
          (unordered_list.as(:unordered) |
             ordered_list.as(:ordered) # definition_list |
            ).as(:list)
        end

        def ordered_list
          (olist_item >> newline.maybe).repeat(1)
        end

        def unordered_list
          (ulist_item >> newline.maybe).repeat(1)
        end

        def definition_list(delimiter = "::")
          dlist_item(delimiter).as(:definition_list).repeat(1) >>
          dlist_item(delimiter).absent?
        end

        def olist_item
          match("^\\.") >> match("\n").absent? >> space >> text_line
        end

        def ulist_item
          match("^\\*") >> match("\n").absent? >> space >> text_line
        end

        def dlist_delimiter
          (str("::") | str(":::") | str("::::") | str(";;")
            ).as(:delimiter)
        end

        def dlist_term(delimiter)
          (match("[^\n:]").repeat(1) #>> empty_line.repeat(0)
            ).as(:term) >> dlist_delimiter
        end

        def dlist_definition
          (text #>> empty_line.repeat(0)
            ).as(:definition) >> line_ending >> empty_line.repeat(0)
        end

        def dlist_item(delimiter)
          (((dlist_term(delimiter).as(:terms).repeat(1) >> line_ending >>
            empty_line.repeat(0)).repeat(1) >>
            dlist_definition)  |
            (dlist_term(delimiter).repeat(1,1).as(:terms) >> space >> dlist_definition)
            ).as(:definition_list_item).repeat(1)
        end
      end
    end
  end
end
