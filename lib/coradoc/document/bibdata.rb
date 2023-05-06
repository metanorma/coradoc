module Coradoc
  module Document
    class Bibdata
      attr_reader :data

      def initialize(bibdata, options = {})
        @bibdata = bibdata
        @options = options
      end

      def data
        @data ||= @bibdata
      end
    end
  end
end
