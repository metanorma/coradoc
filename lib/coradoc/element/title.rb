module Coradoc
  module Element
    class Title < Base
      attr_accessor :id, :content, :line_break, :style, :level_int

      declare_children :id, :content

      def initialize(content:, level:, id: nil, line_break: "", style: nil)
        @level_int = level
        # @level_int = level.length - 1 if level.is_a?(String)
        @content = content
        @id = id
        @anchor = @id.nil? ? nil : Inline::Anchor.new(id: @id)
        @line_break = line_break
        @style = style
      end

      def level
        @level ||= level_from_string
      end

      def to_adoc
        anchor = @anchor.nil? ? "" : "#{@anchor.to_adoc}\n"
        content = Coradoc.strip_unicode(Coradoc::Generator.gen_adoc(@content))
        <<~HERE

          #{anchor}#{style_str}#{level_str} #{content}
        HERE
      end

      def level_str
        if @level_int <= 5
          "=" * (@level_int + 1)
        else
          "======"
        end
      end

      def style_str
        style = [@style]
        style << "level=#{@level_int}" if @level_int > 5
        style = style.compact.join(",")

        "[#{style}]\n" unless style.empty?
      end

      alias :text :content

      private

      def level_from_string
        case @level_int
        when 2 then :heading_two
        when 3 then :heading_three
        when 4 then :heading_four
        when 5 then :heading_five
        else :unknown
        end
      end
    end
  end
end
