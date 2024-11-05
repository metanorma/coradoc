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
        @attached = options.fetch(:attached, [])
        @nested = options.fetch(:nested, nil)
        @line_break = options.fetch(:line_break, "\n")
      end

      def to_adoc
        anchor = @anchor.nil? ? "" : " #{@anchor.to_adoc.to_s} "
        # text = Coradoc::Generator.gen_adoc(@content)
        content = Array(@content).map do |subitem|
          next if subitem.is_a? Inline::HardLineBreak

          subcontent = Coradoc::Generator.gen_adoc(subitem)
          # Only try to postprocess elements that are text,
          # otherwise we could strip markup.
          if Coradoc.a_single?(subitem, Coradoc::Element::TextElement)
            subcontent = Coradoc.strip_unicode(subcontent)
          end
          subcontent
        end.compact.join("\n+\n")
        # attach = Coradoc::Generator.gen_adoc(@attached)
        attach = @attached.map do |elem|
          "+\n" + Coradoc::Generator.gen_adoc(elem)
        end.join
        nest = Coradoc::Generator.gen_adoc(@nested)
        out = " #{anchor}#{content}#{@line_break}"
        out + attach + nest
      end
    end
  end
end
