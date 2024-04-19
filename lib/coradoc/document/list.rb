module Coradoc
  module Document
    class List
      attr_reader :items, :prefix, :id, :ol_count, :anchor

      def initialize(items, options = {})
        @items = items
        @items = [@items] unless @items.is_a?(Array)
        @id = options.fetch(:id, nil)
        @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
        @ol_count = options.fetch(:ol_count, 0)
        @attrs = options.fetch(:attrs, nil)
      end

      def to_adoc
        content = "\n"
        @items.each do |item|
          c = Coradoc::Generator.gen_adoc(item)
          if !c.empty?
            content << "#{prefix}"
            content << c
          end
        end
        anchor = @anchor.nil? ? "" : "#{@anchor.to_adoc}"
        attrs = @attrs.nil? ? "" : "#{@attrs.to_adoc}"
        "\n#{anchor}#{attrs}" + content
      end


      class Ordered < List
        def prefix
          "." * [@ol_count, 0].max
        end
      end

      class Unordered < List
        def prefix
          "*" * [@ol_count, 0].max
        end
      end

      class Definition < List
      end

      class Item
        attr_reader :id
        def initialize(content, options = {})
          @content = content
          @id = options.fetch(:id, nil)
          @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
        end
        def to_adoc
          anchor = @anchor.nil? ? "" : "#{@anchor.to_adoc}"
          content = Coradoc::Generator.gen_adoc(@content).chomp
          " #{anchor}#{content.chomp}\n"
        end
      end
    end
  end
end
