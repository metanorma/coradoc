module Coradoc
  module Element
    class Paragraph < Base
      attr_accessor :content, :anchor, :tdsinglepara

      declare_children :content, :anchor

      def initialize(content, options = {})
        @content = content
        @title = options.fetch(:title, nil)
        @meta = options.fetch(:meta, nil)
        @id = options.fetch(:id, nil)
        @anchor = Inline::Anchor.new(@id) if @id
        @tdsinglepara = options.fetch(:tdsinglepara, nil)
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
        if @tdsinglepara
          "#{title}#{anchor}" << Coradoc.strip_unicode(Coradoc::Generator.gen_adoc(@content))
        else
          "\n\n#{title}#{anchor}" << Coradoc.strip_unicode(Coradoc::Generator.gen_adoc(@content)) << "\n\n"
        end
      end
    end
  end
end
