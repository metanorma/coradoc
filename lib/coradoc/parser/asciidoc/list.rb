module Coradoc
  module Parser
    module Asciidoc
      module List

        def list
          (
          unordered_list |
             ordered_list # definition_list |
            ).as(:list)
        end

        def ordered_list(nesting_level = 1)
          attrs = (attribute_list >> newline).maybe
          r = olist_item(nesting_level)
          if nesting_level <= 8
            r = r | ordered_list(nesting_level + 1)
          end
          attrs >> r.repeat(1).as(:ordered)
        end

        def unordered_list(nesting_level = 1)
          attrs = (attribute_list >> newline).maybe
          r = ulist_item(nesting_level)
          if nesting_level <= 8
            r = r | unordered_list(nesting_level + 1)
          end
          attrs >> r.repeat(1).as(:unordered)
        end

        def definition_list(delimiter = "::")
          (attribute_list >> newline).maybe >>
          dlist_item(delimiter).as(:definition_list).repeat(1) >>
          dlist_item(delimiter).absent?
        end

        def olist_item(nesting_level = 1)
          nl2 = nesting_level - 1
          marker = match(/^\./)
          marker = marker >>  str(".").repeat(nl2, nl2) if nl2 > 0
          str("").as(:list_item) >> 
          marker.as(:marker) >> str(".").absent? >>
          match("\n").absent? >> space >> text_line
        end

        def ulist_item(nesting_level = 1)
          nl2 = nesting_level - 1
          marker = match(/^\*/)
          marker = marker >>  str("*").repeat(nl2, nl2) if nl2 > 0
          str("").as(:list_item) >>
          marker.as(:marker) >> str("*").absent? >>
          match("\n").absent? >> space >> text_line
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
