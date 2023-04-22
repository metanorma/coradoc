module Coradoc
  class Document::Section
    attr_reader :title, :blocks, :paragraphs

    def initialize(title, options = {})
      @title = title
      @blocks = options.fetch(:blocks, [])
      @paragraphs = options.fetch(:paragraphs, [])
    end
  end
end
