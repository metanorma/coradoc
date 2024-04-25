module Coradoc
  module Document
    class Title
      attr_reader :id, :content, :line_break

      def initialize(content, level, options = {})
        @level_int = level
        @level_int = level.length if level.is_a?(String)
        @content = content
        @id = options.fetch(:id, nil)
        @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
        @line_break = options.fetch(:line_break, "")
      end

      def level
        @level_str ||= level_from_string
      end

      def to_adoc
        anchor = @anchor.nil? ? "" : "#{@anchor.to_adoc}\n"
        content = Coradoc::Generator.gen_adoc(@content)
        level_str = "=" * (@level_int + 1)
        content = ["\n", anchor, level_str, ' ', content, "\n"].join("")
      end

      alias :text :content

      private

      attr_reader :level_str

      def level_from_string
        case @level_int
        when 2 then :heading_two
        when 3 then :heading_three
        when 4 then :heading_four
        else :unknown
        end
      end
    end
  end
end
