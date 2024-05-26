module Coradoc
  module Element
    class Admonition < Base
      attr_accessor :type, :content, :line_break

      def initialize(content, type, options = {})
        @content = content
        @type = type.downcase.to_sym
        @line_break = options.fetch(:line_break, "")
      end
    end
  end
end
