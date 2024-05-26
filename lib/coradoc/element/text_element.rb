module Coradoc
  module Element
    class TextElement < Base
      attr_accessor :id, :content, :line_break

      declare_children :content

      def initialize(content, options = {})
        @content = content # .to_s
        @id = options.fetch(:id, nil)
        @line_break = options.fetch(:line_break, "")
      end

      def to_adoc
        Coradoc::Generator.gen_adoc(@content)
      end
    end

    class LineBreak < Base
      attr_reader :line_break

      def initialize(line_break)
        @line_break = line_break
      end
    end

    class Highlight < Element::TextElement
    end
  end
end
