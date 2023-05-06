module Coradoc
  module Document
    class Base
      attr_reader :bibdata

      def initialize(asciidoc)
        @bibdata = extract_bibdata(asciidoc)
      end

      private

      def extract_bibdata(asciidoc)
        @bibdata ||= BibData.new(asciidoc.attributes)
      end
    end
  end
end
