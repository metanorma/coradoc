module Coradoc
  module Element
    class ListItem < Base
      attr_accessor :marker, :id, :anchor, :content, :line_break

      declare_children :content, :id, :anchor

      def initialize(content, options = {})
        @marker = options.fetch(:marker, nil)
        @id = options.fetch(:id, nil)
        @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
        @content = content
        @line_break = options.fetch(:line_break, "\n")
      end

      def to_adoc
        anchor = @anchor.nil? ? "" : @anchor.to_adoc.to_s
        content = Array(@content).map do |subitem|
          next if subitem.is_a? Inline::HardLineBreak

          subcontent = Coradoc::Generator.gen_adoc(subitem)
          # Only try to postprocess elements that are text,
          # otherwise we could strip markup.
          if Coradoc.is_a_single?(subitem, Coradoc::Element::TextElement)
            subcontent = Coradoc.strip_unicode(subcontent)
          end
          subcontent.chomp
        end.compact.join("\n+\n")

        " #{anchor}#{content.chomp}#{@line_break}"
      end
    end
  end
end
