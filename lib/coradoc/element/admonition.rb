module Coradoc
  module Element
    class Admonition < Base
      attr_accessor :type, :content, :line_break

      def initialize(content, type, options = {})
        @content = content
        @type = type.downcase.to_sym
        @line_break = options.fetch(:line_break, "")
      end

      def to_s
        content = Coradoc::Generator.gen_adoc(@content)
        "#{type.to_s.upcase}: #{content}"
      end

    end
  end
end
