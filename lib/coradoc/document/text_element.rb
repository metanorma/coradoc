module Coradoc
  class Document::TextElement
    attr_reader :content, :line_break

    def initialize(content, options = {})
      @content = content
      @line_break = options.fetch(:line_break, "")
    end
  end
end
