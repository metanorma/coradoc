module Coradoc
  module Element
    module Inline
      class Italic
        attr_accessor :content, :unconstrained

        def initialize(content, unconstrained = true)
          @content = content
          @unconstrained = unconstrained
        end

        def to_adoc
          content = Coradoc::Generator.gen_adoc(@content)
          doubled = @unconstrained ? "_" : ""
          "#{content[/^\s+/]}#{doubled}_#{content.strip}_#{doubled}#{content[/\s+$/]}"
        end
      end
    end
  end
end
