module Coradoc
  module Document
    class Block
      attr_reader :title, :lines, :attributes

      def initialize(title, options = {})
        @title = title
        @lines = options.fetch(:lines, [])
        @type_str = options.fetch(:type, nil)
        @delimiter = options.fetch(:delimiter, "")
        @attributes = options.fetch(:attributes, {})
      end

      def type
        @type ||= defined_type || type_from_delimiter
      end

      private

      def defined_type
        @type_str&.to_s&.to_sym
      end

      def type_from_delimiter
        type_hash.fetch(@delimiter, nil)
      end

      def type_hash
        @type_hash ||= {
          "____" => :quote,
          "****" => :side,
          "----" => :source,
          "====" => :example,
        }
      end
    end
  end
end
