module Coradoc
  module Element
    class Table < Base
      attr_accessor :title, :rows, :content, :id

      declare_children :title, :rows, :id

      def initialize(title:, rows:, id: nil, attributes: nil)
        @rows = rows
        @title = title
        @id = id
        @anchor = @id.nil? ? nil : Inline::Anchor.new(id: @id)
        @attrs = attributes
      end

      def to_adoc
        anchor = @anchor.nil? ? "" : "#{@anchor.to_adoc}\n"
        attrs = @attrs.to_s.empty? ? "" : "#{@attrs.to_adoc}\n"
        title = Coradoc::Generator.gen_adoc(@title)
        title = title.empty? ? "" : ".#{title}\n"
        content = @rows.map(&:to_adoc).join
        "\n\n#{anchor}#{attrs}#{title}|===\n" << content << "\n|===\n"
      end

      class Row < Base
        attr_accessor :columns, :header

        declare_children :columns

        def initialize(columns:, header: false)
          @columns = columns
          @header = header
        end

        def table_header_row?
          @header
        end

        def asciidoc?
          @columns.any? { |c| c.respond_to?(:asciidoc?) && c.asciidoc? }
        end

        def to_adoc
          delim = asciidoc? ? "\n" : " "
          content = @columns.map do |col|
            Coradoc::Generator.gen_adoc(col)
          end.join(delim)
          result  = "#{content}\n"
          result << "\n" if asciidoc?
          table_header_row? ? result + underline_for : result
        end

        def underline_for
          "\n"
        end
      end

      class Cell < Base
        attr_accessor :content, :anchor, :id, :colrowattr, :alignattr, :style

        declare_children :content, :anchor, :id

        def initialize(id: nil, colrowattr: "", alignattr: "", style: "",
content: "")
          super()
          @id = id
          @anchor = @id.nil? ? nil : Inline::Anchor.new(id: @id)
          @colrowattr = colrowattr
          @alignattr = alignattr
          @style = style
          @content = content
        end

        def asciidoc?
          @style.include?("a")
        end

        def to_adoc
          anchor = @anchor.nil? ? "" : @anchor.to_adoc.to_s
          content = simplify_block_content(@content)
          content = Coradoc::Generator.gen_adoc(content)
          # Only try to postprocess elements that are text,
          # otherwise we could strip markup.
          if Coradoc.a_single?(@content, Coradoc::Element::TextElement)
            content = Coradoc.strip_unicode(content)
          end
          "#{@colrowattr}#{@alignattr}#{@style}| #{anchor}#{content}"
        end
      end
    end
  end
end
