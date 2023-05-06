module Coradoc
  module Parser
    module Asciidoc
      module Bibdata
        include Coradoc::Parser::Asciidoc::Base

        # Bibdata
        def bibdatas
          bibdata.repeat(1)
        end

        def bibdata
          str(":") >> attribute_name.as(:key) >> str(":") >>
          space? >> attribute_value.as(:value) >> line_ending
        end
      end
    end
  end
end
