module Coradoc
  module Element
    module Inline
      class Italic < Base
        attr_accessor :content, :unconstrained

        declare_children :content

        def initialize(content, unconstrained: true)
          @content = content
          @unconstrained = unconstrained
        end

        def to_adoc
          content = Coradoc::Generator.gen_adoc(@content)
          if @unconstrained
            "__#{content}__"
          else
            "_#{content}_"
          end
        end
      end
    end
  end
end
