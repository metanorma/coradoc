module Coradoc
  module Element
    class Table
      attr_reader :title, :rows, :content, :id

      def initialize(title, rows, options = {})
        @rows = rows
        @title = title
        @id = options.fetch(:id, nil)
        @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
        @attrs = options.fetch(:attrs, "")
      end

      def to_adoc
        anchor = @anchor.nil? ? "" : "#{@anchor.to_adoc}\n"
        attrs = @attrs.to_s.empty? ? "" : "#{@attrs.to_adoc}\n"
        title = Coradoc::Generator.gen_adoc(@title)
        title = title.empty? ? "" : ".#{title}\n"
        content = @rows.map(&:to_adoc).join
        "\n\n#{anchor}#{attrs}#{title}|===\n" << content << "\n|===\n"
      end

      class Row
        attr_reader :columns, :header

        def initialize(columns, header = false)
          @columns = columns
          @header = header
        end

        def table_header_row?
          @header
        end

        def to_adoc
          content = Coradoc::Generator.gen_adoc(@columns).rstrip
          result  = "#{content}\n"
          table_header_row? ? result + underline_for : result
        end

        def underline_for
          "\n"
        end
      end

      class Cell
        attr_reader :anchor

        def initialize(options = {})
          @id = options.fetch(:id, nil)
          @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
          @colrowattr = options.fetch(:colrowattr, "")
          @alignattr = options.fetch(:alignattr, "")
          @style = options.fetch(:style, "")
          @content = options.fetch(:content, "")
          @delim = options.fetch(:delim, "")
        end

        def to_adoc
          anchor = @anchor.nil? ? "" : @anchor.to_adoc.to_s
          content = Coradoc::Generator.gen_adoc(@content)
          "#{@colrowattr}#{@alignattr}#{@style}| #{anchor}#{content}#{@delim}"
        end
      end
    end
  end
end
