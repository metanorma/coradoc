module Coradoc
  class Document::Section
    attr_reader :id, :title, :contents, :sections

    def initialize(title, options = {})
      @title = title
      @id = options.fetch(:id, nil)
      @contents = options.fetch(:contents, [])
      @sections = options.fetch(:sections, [])
    end
  end
end
