module Coradoc
  module Parser
    module Asciidoc
      module DocumentAttributes

        def document_attributes
          (document_attribute.repeat(1)
            ).as(:document_attributes)
        end

        def document_attribute
          str(":") >> attribute_name.as(:key) >> str(":") >>
            space? >> attribute_value.as(:value) >> line_ending
        end
      end
    end
  end
end
