# $DEBUG = true
module Coradoc
  module Parser
    module Asciidoc
      module List
        def list(nesting_level = 1)
          (
          unordered_list(nesting_level) |
             ordered_list(nesting_level) |
             definition_list
        ).as(:list)
        end

        def list_continuation
          line_start? >> str("+\n")
        end

        def ordered_list(nesting_level = 1)
          attrs = (attribute_list >> newline).maybe
          r = olist_item(nesting_level)
          attrs >> olist_item(nesting_level).present? >> r.repeat(1).as(:ordered)
        end

        def unordered_list(nesting_level = 1)
          attrs = (attribute_list >> newline).maybe
          r = ulist_item(nesting_level)
          attrs >> r.repeat(1).as(:unordered)
        end

        def definition_list(delimiter = "::")
          (attribute_list >> newline).maybe >>
            dlist_item(delimiter).repeat(1).as(:definition_list) >>
            dlist_item(delimiter).absent?
        end

        def list_marker(nesting_level = 1)
          olist_marker(nesting_level) | ulist_marker(nesting_level)
        end

        def olist_marker(nesting_level = 1)
          line_start? >> str("." * nesting_level) >> str(".").absent?
        end

        def olist_item(nesting_level = 1)
          item = olist_marker(nesting_level).as(:marker) >>
            match("\n").absent? >> space >> text_line(true)
          # >>
          # (list_continuation.present? >> list_continuation >>
          # paragraph #| example_block(n_deep: 1)
          # ).repeat(0).as(:attached)

          att = (list_continuation.present? >>
                  list_continuation >>
                  (admonition_line | paragraph | block) # (n_deep: 1))
                ).repeat(0).as(:attached)
          item = item >> att.maybe

          if nesting_level <= 4
            item = item >>
              (list_marker(nesting_level + 1).present? >>
              list(nesting_level + 1)).repeat(0).as(:nested) # ).maybe
          end
          olist_marker(nesting_level).present? >> item.as(:list_item)
        end

        def ulist_marker(nesting_level = 1)
          line_start? >> str("*" * nesting_level) >> str("*").absent?
        end

        def ulist_item(nesting_level = 1)
          item = ulist_marker(nesting_level).as(:marker) >>
            str(" [[[").absent? >>
            match("\n").absent? >> space >> text_line(true)

          att = (list_continuation.present? >>
                  list_continuation >>
                  (admonition_line | paragraph | block) # (n_deep: 1))
                ).repeat(0).as(:attached)
          item = item >> att.maybe

          if nesting_level <= 4
            item = item >>
              (list_marker(nesting_level + 1).present? >>
              list(nesting_level + 1)).repeat(0).as(:nested) # ).maybe
          end
          ulist_marker(nesting_level).present? >> item.as(:list_item)
        end

        def dlist_delimiter
          (str("::") | str(":::") | str("::::") | str(";;")
          ).as(:delimiter)
        end

        def dlist_term(_delimiter)
          match("[^\n:]").repeat(1) # >> empty_line.repeat(0)
            .as(:dlist_term) >> dlist_delimiter
        end

        def dlist_definition
          text # >> empty_line.repeat(0)
            .as(:definition) >> line_ending >> empty_line.repeat(0)
        end

        def dlist_item(delimiter)
          (((dlist_term(delimiter).as(:terms).repeat(1) >> line_ending >>
            empty_line.repeat(0)).repeat(1) >>
            dlist_definition) |
            (dlist_term(delimiter).repeat(1, 1).as(:terms) >> space >>
              dlist_definition)
          ).as(:definition_list_item)
        end
      end
    end
  end
end
