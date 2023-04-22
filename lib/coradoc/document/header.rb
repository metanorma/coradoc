module Coradoc
  class Document::Header
    attr_reader :title, :author, :revision

    def initialize(title, options = {})
      @title = title
      @author = options.fetch(:author, nil)
      @revision = options.fetch(:revision, nil)
    end
  end
end
