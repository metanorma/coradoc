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
        anchor = @anchor.nil? ? "" : "#{@anchor.to_adoc}"
        content = Coradoc::Generator.gen_adoc(@content).chomp
        " #{anchor}#{content.chomp}\n"
      end
    end
  end
end
