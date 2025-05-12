module Coradoc
  module Element
    class Paragraph < Base
      attr_accessor :content, :anchor, :tdsinglepara

      declare_children :content, :anchor

      def initialize(content:, id: nil, title: nil, attributes: nil,
tdsinglepara: nil)
        @content = content
        @id = id
        @anchor = @id.nil? ? nil : Inline::Anchor.new(id: @id)
        @title = title
        @attributes = attributes
        @tdsinglepara = tdsinglepara
      end

      def id
        content&.first&.id&.to_s
      end

      def texts
        content.map(&:content)
      end

      def to_adoc
        title = @title.nil? ? "" : ".#{Coradoc::Generator.gen_adoc(@title)}\n"
        anchor = @anchor.nil? ? "" : "#{@anchor.to_adoc}\n"
        attrs = @attributes.nil? ? "" : "#{@attributes.to_adoc}\n"
        if @tdsinglepara
          "#{title}#{anchor}" << Coradoc.strip_unicode(Coradoc::Generator.gen_adoc(@content))
        else
          "\n\n#{title}#{anchor}#{attrs}" << Coradoc.strip_unicode(Coradoc::Generator.gen_adoc(@content)) << "\n\n"
        end
      end
    end
  end
end
