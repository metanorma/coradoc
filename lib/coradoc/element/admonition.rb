module Coradoc
  module Element
    class Admonition < Base
      attr_accessor :type, :content, :line_break

      def initialize(content:, type:, line_break: "")
        @content = content
        @type = type.downcase.to_sym
        @line_break = line_break
      end

      def to_adoc
        content = Coradoc::Generator.gen_adoc(@content)
        "#{type.to_s.upcase}: #{content}#{@line_break}"
      end
    end
  end
end
