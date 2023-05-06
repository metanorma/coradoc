module Coradoc
  class Document::TextElement
    attr_reader :id, :content, :line_break

    def initialize(content, options = {})
      @content = content
      @id = options.fetch(:id, nil)
      @line_break = options.fetch(:line_break, "")
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
