module Coradoc
  module Document
    class Table
      attr_reader :title, :rows

      def initialize(title, rows)
        @rows = rows
        @title = title
      end

      class Row
        attr_reader :columns

        def initialize(columns)
          @columns = columns
        end
      end
    end
  end
end
