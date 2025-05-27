module Coradoc
  module Element
    class Term < Base
      attr_accessor :term, :options

      declare_children :term, :options

      def initialize(term:, type: nil, lang: :en, line_break: "")
        @term = term
        @type = type
        @lang = lang
        @line_break = line_break
      end

      def to_adoc
        return "#{@type}:[#{@term}]#{@line_break}" if @lang == :en

        "[#{@type}]##{@term}##{@line_break}"
      end
    end
  end
end
