module Coradoc
  module Document
    class List
      attr_reader :items, :prefix, :id, :ol_count

      def initialize(items, options = {})
        @items = items
        @items = [@items] unless @items.is_a?(Array)
        @id = options.fetch(:id, nil)
        @ol_count = options.fetch(:ol_count, 0)
        @anchor = options.fetch(:anchor, nil)
        @attrs = options.fetch(:attrs, nil)
      end

      def to_adoc
        content = ""
        @items.each do |item|
          c = Coradoc::Generator.gen_adoc(item)
          if !c.empty?
            content << "#{prefix}"
            content << c
          end
        end
        "\n#{@anchor}#{@attrs}" + content
      end


      def prefix
        "." * [@ol_count, 0].max
      end

      class Unordered < List
        def prefix
          "*" * [@ol_count, 0].max
        end
      end

      class Item
        def initialize(content, options = {})
          @content = content
          @anchor = options.fetch(:anchor, '')
        end
        def to_adoc
          content = Coradoc::Generator.gen_adoc(@content)
          " #{@anchor}#{content.chomp}\n"
        end
      end
    end
  end
end
