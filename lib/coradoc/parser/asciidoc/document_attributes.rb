module Coradoc
  module Parser
    module Asciidoc
      module DocumentAttributes
        include Coradoc::Parser::Asciidoc::Base

        # DocumentAttributes
        def document_attributess
          document_attributes.repeat(1)
        end

        def document_attributes
          str(":") >> attribute_name.as(:key) >> str(":") >>
            space? >> attribute_value.as(:value) >> line_ending
        end
      end
    end
  end
end
