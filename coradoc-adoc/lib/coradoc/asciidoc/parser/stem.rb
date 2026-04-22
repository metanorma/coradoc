# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Parser
      module Stem
        def stem_type
          (str('stem') | str('latexmath') | str('asciimath')).as(:stem_type)
        end

        def stem
          (stem_type >> str(':[') >>
            match('[^\]]').repeat(1).as(:content) >>
            str(']')).as(:stem)
        end
      end
    end
  end
end
