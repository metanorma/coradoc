module Coradoc
  module Element
    class ListItem < Base
      attr_accessor :id

      declare_children :content, :id, :anchor

      def initialize(content, options = {})
        @content = content
        @id = options.fetch(:id, nil)
        @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
      end

      def to_adoc
        anchor = @anchor.nil? ? "" : @anchor.to_adoc.to_s
        content = Array(@content).map do |subitem|
          subcontent = Coradoc::Generator.gen_adoc(subitem)
          # Only try to postprocess elements that are text,
          # otherwise we could strip markup.
          if Coradoc.is_a_single?(subitem, Coradoc::Element::TextElement)
            subcontent = Coradoc.strip_unicode(subcontent)
          end
          subcontent.chomp
        end.join("\n+\n")

        " #{anchor}#{content.chomp}\n"
      end
    end
  end
end
