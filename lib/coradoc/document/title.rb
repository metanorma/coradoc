module Coradoc
  class Document::Title
    attr_reader :id, :content, :line_break

    def initialize(content, level, options = {})
      @level_str = level
      @content = content
      @id = options.fetch(:id, nil)
      @line_break = options.fetch(:line_break, "")
    end

    def level
      @level ||= level_from_string
    end

    private

    attr_reader :level_str

    def level_from_string
      case @level_str.length
      when 2 then :heading_two
      when 3 then :heading_three
      when 4 then :heading_four
      else :unknown
      end
    end
  end
end
