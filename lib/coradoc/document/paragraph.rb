module Coradoc
  module Document
    class Paragraph
      attr_reader :content

      def initialize(content, _options = {})
        @content = content
      end
    end
  end
end
