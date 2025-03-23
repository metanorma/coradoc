module Coradoc
  module Parser
    module Asciidoc
      module DocumentAttributes
        def attribute_name
          match("[a-zA-Z0-9_-]").repeat(1)
        end

        def attribute_value
          text | str("") >> str("\n").absent?
        end

        def document_attributes
          document_attribute.repeat(1)
            .as(:document_attributes)
        end

        def document_attribute
          str(":") >> attribute_name.as(:key) >> str(":") >>
            space? >> (attribute_value | str("")).as(:value) >> line_ending
        end
      end
    end
  end
end
