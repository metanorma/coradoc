module Coradoc
  class Document::Header
    attr_reader :title, :author, :revision

    def initialize(title, options = {})
      @title = title
      @author = options.fetch(:author, nil)
      @revision = options.fetch(:revision, nil)
    end

    def to_adoc
      adoc = "= #{title}\n"
      adoc << @author.to_adoc if @author
      adoc << @revision.to_adoc if @revision
      adoc
    end
  end
end
