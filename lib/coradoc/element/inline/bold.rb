module Coradoc
  module Element
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
          "#{doubled}*#{content}*#{doubled}"
        end
      end
    end
  end
end
