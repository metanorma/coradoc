module Coradoc
  module Element
    class BibliographyEntry < Base
      attr_accessor :anchor_name, :document_id, :reference_text, :line_break

      def initialize(options = {})
        @anchor_name = options.fetch(:anchor_name, nil)
        @document_id = options.fetch(:document_id, nil)
        @reference_text = options.fetch(:reference_text, nil)
        @line_break = options.fetch(:line_break, nil)
      end

      def to_adoc
        adoc = "* [[[#{@anchor_name}"
        adoc << ",#{@document_id}" if @document_id
        adoc << "]]]"
        adoc << "#{@reference_text}" if @reference_text
        adoc << @line_break
        adoc
      end
    end
  end
end
