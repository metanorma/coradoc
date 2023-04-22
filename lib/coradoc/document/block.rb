module Coradoc
  class Document::Block
    attr_reader :title, :lines, :attributes

    def initialize(title, options = {})
      @title = title
      @lines = options.fetch(:lines, [])
      @type_str = options.fetch(:type, nil)
      @delimiter = options.fetch(:delimiter, "")
      @attributes = options.fetch(:attributes, {})
    end

    def type
      @type ||= defined_type || type_from_delimiter
    end

    private

    def defined_type
      if @type_str
        @type_str.to_s.to_sym
      end
    end

    def type_from_delimiter
      case @delimiter
      when "____" then :quote
      when "****" then :side
      when "----" then :source
      when "====" then :example
      else nil end
    end
  end
end
