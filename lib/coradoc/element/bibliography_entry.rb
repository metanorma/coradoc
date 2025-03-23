module Coradoc
  module Element
    class BibliographyEntry < Base
      attr_accessor :anchor_name, :document_id, :ref_text, :line_break

      def initialize(options = {})
        @anchor_name = options.fetch(:anchor_name, nil)
        @document_id = options.fetch(:document_id, nil)
        @ref_text = options.fetch(:ref_text, nil)
        @line_break = options.fetch(:line_break, "")
      end

      def to_adoc
        text = Coradoc::Generator.gen_adoc(@ref_text) if @ref_text
        adoc = "* [[[#{@anchor_name}"
        adoc << ",#{@document_id}" if @document_id
        adoc << "]]]"
        adoc << text.to_s if @ref_text
        adoc << @line_break
        adoc
      end
    end
  end
end
