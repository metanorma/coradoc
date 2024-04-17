module Coradoc
  class Document::Header
    attr_reader :title, :author, :revision

    def initialize(title, options = {})
      @title = title
      @author = options.fetch(:author, nil)
      @revision = options.fetch(:revision, nil)
    end

    def to_adoc
      "= #{title}\n:stem:\n\n"
    end
  end
end
