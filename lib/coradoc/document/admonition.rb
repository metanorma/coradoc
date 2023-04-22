module Coradoc
  class Document::Admonition
    attr_reader :type, :content, :line_break

    def initialize(content, type, options = {})
      @content = content
      @type = type.downcase.to_sym
      @line_break = options.fetch(:line_break, "")
    end
  end
end
