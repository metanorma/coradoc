module Coradoc
  module Document
    class Paragraph
      attr_reader :content

      def initialize(content, options = {})
        @content = content
        @meta = options.fetch(:meta, nil)
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
