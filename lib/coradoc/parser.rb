module Coradoc
  class Parser
    def initialize(filename)
      @filename = filename
    end

    def self.parse(filename)
      new(filename).parse
    end

    def parse
      asciidoc = Asciidoctor.load_file(@filename, safe: :safe)
      Coradoc::Document::Base.new(asciidoc)
    end
  end
end
