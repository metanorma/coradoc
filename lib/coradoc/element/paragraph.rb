module Coradoc
  module Element
    class Paragraph < Base
      attr_accessor :content, :anchor, :tdsinglepara

      declare_children :content, :anchor

      def initialize(content, options = {})
        @content = content
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
        anchor = @anchor.nil? ? "" : "#{@anchor.to_adoc}\n"
        if @tdsinglepara
          anchor.to_s << Coradoc.strip_unicode(Coradoc::Generator.gen_adoc(@content))
        else
          "\n\n#{anchor}" << Coradoc.strip_unicode(Coradoc::Generator.gen_adoc(@content)) << "\n\n"
        end
      end
    end
  end
end
