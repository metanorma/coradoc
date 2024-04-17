module Coradoc
  module Document
    class Paragraph
      attr_reader :content, :id, :tdsinglepara

      def initialize(content, options = {})
        @content = content
        @meta = options.fetch(:meta, nil)
        @id = options.fetch(:id, nil)
        @tdsinglepara = options.fetch(:tdsinglepara, nil)
      end

      def id
        content&.first&.id&.to_s
      end

      def texts
        content.map(&:content)
      end

      def to_adoc
        anchor = @id ? "[[#{@id}]]\n" : ""
        if @tdsinglepara
          "#{anchor}" << Coradoc::Generator.gen_adoc(@content).strip
        else
          "\n\n#{anchor}" << Coradoc::Generator.gen_adoc(@content).strip << "\n\n"
        end
      end
    end
  end
end
