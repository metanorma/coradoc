module Coradoc
  module Element
    class ListItem
      attr_reader :id

      def initialize(content, options = {})
        @content = content
        @id = options.fetch(:id, nil)
        @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
      end

      def to_adoc
        anchor = @anchor.nil? ? "" : @anchor.to_adoc.to_s
        case @content
        when Array
          content = @content.map{|subitem| Coradoc::Generator.gen_adoc(subitem).chomp}.join("\n+\n")
        else
          content = Coradoc::Generator.gen_adoc(@content).chomp
        end
        " #{anchor}#{content.chomp}\n"
      end
    end
  end
end
