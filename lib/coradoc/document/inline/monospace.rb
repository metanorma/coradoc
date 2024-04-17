module Coradoc
  module Document
    module Inline
      class Monospace
        attr_accessor :content
        def initialize(content)
          @content = content
        end
        def to_adoc
          content = Coradoc::Generator.gen_adoc(@content)
          "`#{content}`"
        end
      end
    end
  end
end
