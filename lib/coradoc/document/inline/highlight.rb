module Coradoc
  module Document
    module Inline
      class Highlight
        attr_accessor :content
        def initialize(content, constrained = true)
          @content = content
          @constrained = constrained
        end
        def to_adoc
          content = Coradoc::Generator.gen_adoc(@content)
          doubled = @constrained ? "" : "#"
          "#{content[/^\s*/]}#{doubled}##{content.strip}##{doubled}#{content[/\s*$/]}"
        end
      end
    end
  end
end
