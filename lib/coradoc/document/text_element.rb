module Coradoc
  class Document::TextElement
    attr_reader :id, :content, :line_break

    def initialize(content, options = {})
      @content = content#.to_s
      @id = options.fetch(:id, nil)
      @line_break = options.fetch(:line_break, "")
    end
    
    def to_adoc
      Coradoc::Generator.gen_adoc(@content)
    end
  end

  class Document::LineBreak
    attr_reader :line_break

    def initialize(line_break)
      @line_break = line_break
    end
  end

  class Document::Highlight < Document::TextElement
  end
end
