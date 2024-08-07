module Coradoc
  module Element
    class Term < Base
      attr_accessor :term, :options

      declare_children :term, :options

      def initialize(term, options = {})
        @term = term
        @type = options.fetch(:type, nil)
        @lang = options.fetch(:lang, :en)
        @line_break = options.fetch(:line_break, "")
      end

      def to_adoc
        return "#{@type.to_s}:[#{@term}]#{@line_break}" if @lang == :en
        return "[#{@type.to_s}]##{@term}]##{@line_break}" if @lang == :fr
      end
    end
  end
end