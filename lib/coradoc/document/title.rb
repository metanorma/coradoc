module Coradoc
  module Document
    class Title
      attr_reader :id, :content, :line_break

      def initialize(content, level, options = {})
        @level_str = level
        @content = content.to_s
        @id = options.fetch(:id, nil).to_s
        @line_break = options.fetch(:line_break, "")
        @anchor = options.fetch(:anchor, nil)
      end

      def level
        @level ||= level_from_string
      end

      def to_adoc
        content = Coradoc::Generator.gen_adoc(@content)
        content = ["\n", @anchor, @level_str, ' ', content, "\n"].join("")
        Coradoc::Generator.gen_adoc(content)
      end

      alias :text :content

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
end
