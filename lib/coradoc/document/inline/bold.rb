module Coradoc
  module Document
    module Inline
      class Bold
        attr_accessor :content, :unconstrained
        def initialize(content, unconstrained = true)
          @content = content
          @unconstrained = unconstrained
        end
        def to_adoc
          content = Coradoc::Generator.gen_adoc(@content)
          doubled = @unconstrained ? "*" : ""
          "#{doubled}*#{content.strip}*#{doubled}#{content[/\s+$/]}"
        end
      end
    end
  end
end
