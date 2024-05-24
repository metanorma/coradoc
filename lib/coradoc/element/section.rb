module Coradoc
  module Element
    class Section
      attr_reader :id, :title, :contents, :sections

      def initialize(title, options = {})
        @title = title
        @id = options.fetch(:id, nil)
        @contents = options.fetch(:contents, [])
        @sections = options.fetch(:sections, [])
        @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
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
        content = Coradoc::Generator.gen_adoc(@contents)
        "\n#{anchor}" << content << "\n"
      end

      # Check for cases when Section is simply an equivalent of an empty <DIV>
      # HTML element and if it happens inside some other block element, can be
      # safely collapsed.
      def safe_to_collapse?
        @id.nil?
      end

      private

      def extract_glossaries
        contents.grep(Coradoc::Element::Glossaries).first
      end
    end
  end
end
