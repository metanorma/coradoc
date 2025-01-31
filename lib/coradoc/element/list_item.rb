module Coradoc
  module Element
    class ListItem < Base
      attr_accessor :marker, :id, :anchor, :content, :subitem, :line_break

      declare_children :content, :id, :anchor

      def initialize(content, options = {})
        @marker = options.fetch(:marker, nil)
        @id = options.fetch(:id, nil)
        @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
        @content = content
        # @content = [@content] unless @content.class == Array
        @attached = options.fetch(:attached, [])
        @nested = options.fetch(:nested, nil)
        @line_break = options.fetch(:line_break, "\n")
      end

      def inline?(elem)
        case elem
        when Inline::HardLineBreak
          :hardbreak
        when ->(i){ i.class.name.to_s.include? "::Inline::" }
          true
        when String, TextElement, Image::InlineImage
          true
        else
          false
        end
      end

      def to_adoc
        anchor = @anchor.nil? ? "" : " #{@anchor.to_adoc.to_s} "
        
        content = Array(@content).flatten.compact
        out = ""
        prev_inline = :init

        # Collapse meaningless <DIV>s
        while content.map(&:class) == [Section] && content.first.safe_to_collapse?
          content = Array(content.first.contents)
        end

        content.each_with_index do |subitem, idx|
          subcontent = Coradoc::Generator.gen_adoc(subitem)
          inline = inline?(subitem)
          next_inline = idx+1 == content.length ? :end : inline?(content[idx+1])

          # Only try to postprocess elements that are text,
          # otherwise we could strip markup.
          if subitem.is_a? Coradoc::Element::TextElement
            if [:hardbreak, :init, false].include?(prev_inline)
              subcontent = Coradoc.strip_unicode(subcontent, only: :begin)
            end
            if [:hardbreak, :end, false].include?(next_inline)
              subcontent = Coradoc.strip_unicode(subcontent, only: :end)
            end
          end

          case inline
          when true
            if prev_inline == false
              out += "\n+\n" + subcontent
            else
              out += subcontent
            end
          when false
            case prev_inline
            when :hardbreak
              out += subcontent.strip
            when :init
              out += "{empty}\n+\n" + subcontent.to_s.strip
            else
              out += "\n+\n" + subcontent.to_s.strip
            end
          when :hardbreak
            if %i[hardbreak init].include? prev_inline
              # can't have two hard breaks in a row; can't start with a hard break
            else
              out += "\n+\n"
            end
          end

          prev_inline = inline
        end
        out += "{empty}" if prev_inline == :hardbreak
        out = "{empty}" if out.empty?

        attach = @attached.map do |elem|
          "+\n" + Coradoc::Generator.gen_adoc(elem)
        end.join
        nest = Coradoc::Generator.gen_adoc(@nested)
        out = " #{anchor}#{out}#{@line_break}"
        out + attach + nest
      end
    end
  end
end
