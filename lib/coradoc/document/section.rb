module Coradoc
  class Document::Section
    attr_reader :id, :title, :contents, :sections

    def initialize(title, options = {})
      @title = title
      @id = options.fetch(:id, nil).to_s
      @contents = options.fetch(:contents, [])
      @sections = options.fetch(:sections, [])
    end

    def glossaries
      @glossaries ||= extract_glossaries
    end

    def content
      if contents.count == 1 && contents.first.is_a?(Coradoc::Document::Paragraph)
        contents.first
      end
    end

    private

    def extract_glossaries
      contents.select {|c| c if c.is_a?(Coradoc::Document::Glossaries) }.first
    end
  end
end
