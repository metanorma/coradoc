module Coradoc
  module Element
    class Section < Base
      attr_accessor :id, :title, :attrs, :contents, :sections, :anchor

      declare_children :id, :title, :contents, :sections

      def initialize(title, options = {})
        @title = title
        @id = options.fetch(:id, nil)
        @id = nil if @id == ""
        @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
        @attrs = options.fetch(:attribute_list, "")
        @contents = options.fetch(:contents, [])
        @sections = options.fetch(:sections, [])
      end

      def glossaries
        @glossaries ||= extract_glossaries
      end

      def content
        if contents.count == 1 && contents.first.is_a?(Coradoc::Element::Paragraph)
          contents.first
        end
      end

      def to_adoc
        anchor = @anchor.nil? ? "" : "#{@anchor.to_adoc}\n"
        title = Coradoc::Generator.gen_adoc(@title)
        attrs = @attrs.to_s.empty? ? "" : "#{@attrs.to_adoc}\n"
        content = Coradoc::Generator.gen_adoc(@contents)
        sections = Coradoc::Generator.gen_adoc(@sections)

        # A block of " +\n"s isn't parsed correctly. It needs to start
        # with something.
        content = "&nbsp;#{content}" if content.start_with?(" +\n")

        # Only try to postprocess elements that are text,
        # otherwise we could strip markup.
        if Coradoc.a_single?(@contents, Coradoc::Element::TextElement)
          content = Coradoc.strip_unicode(content)
        end

        "\n#{anchor}" << attrs << title << content << sections << "\n"
      end

      # Check for cases when Section is simply an equivalent of an empty <DIV>
      # HTML element and if it happens inside some other block element, can be
      # safely collapsed.
      def safe_to_collapse?
        @title.nil? && @sections.empty?
      end

      private

      def extract_glossaries
        contents.grep(Coradoc::Element::Glossaries).first
      end
    end
  end
end
