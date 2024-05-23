module Coradoc
  module Element
    module Inline
      class Highlight
        attr_accessor :content, :unconstrained

        def initialize(content, unconstrained = true)
          @content = content
          @unconstrained = unconstrained
        end

        def to_adoc
          content = Coradoc::Generator.gen_adoc(@content)
          if @unconstrained
            "###{content}##"
          else
            "##{content}#"
          end
        end
      end
    end
  end
end
