module Coradoc
  module Document
    module Inline
      class Bold
        attr_accessor :content, :constrained
        def initialize(content, constrained = true)
          @content = content
          @constrained = constrained
        end
        def to_adoc
          content = Coradoc::Generator.gen_adoc(@content)
          second_char = @constrained ? "" : "*"
          "#{content[/^\s*/]}#{second_char}*#{content.strip}*#{second_char}#{content[/\s*$/]}"
        end
      end
    end
  end
end
