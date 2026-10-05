# frozen_string_literal: true

module Coradoc
  module Markdown
    module Parser
      # Kramdown attribute-list rules shared by block and inline
      # elements: IAL ({:.class #id key="value"}) and ALD
      # ({:name: #id .class key="value"}).
      module AttributeLists
        def ial_class
          str('.') >> match['\\w\\-'].repeat(1)
        end

        def ial_id
          str('#') >> match['\\w\\-'].repeat(1)
        end

        def ial_key_value
          match['\\w\\-'].repeat(1) >> str('=') >>
            (
              (str('"') >> match['^"'].repeat(0) >> str('"')) |
              (str("'") >> match["^'"].repeat(0) >> str("'")) |
              match['^\\s\\}'].repeat(1)
            )
        end

        def ial_content
          (
            whitespace.repeat >>
            (ial_class | ial_id | ial_key_value)
          ).repeat(1)
        end

        def ial
          str('{:') >> ial_content.as(:ial) >> str('}')
        end

        def ald_name
          match['\\w'].repeat(1) >> str(':')
        end

        def ald
          str('{:') >> ald_name.as(:ald_name) >> whitespace.repeat(1) >> ial_content.as(:ial) >> str('}')
        end
      end
    end
  end
end
