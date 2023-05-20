module Coradoc
  module Document
    class Paragraph
      attr_reader :content

      def initialize(content, _options = {})
        @content = content
      end

      def id
        content&.first&.id&.to_s
      end

      def texts
        content.map(&:content)
      end
    end
  end
end
