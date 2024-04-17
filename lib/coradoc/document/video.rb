module Coradoc
  module Document
    class Video
      attr_reader :id, :title, :src, :options

      def initialize(title, options = {})
        @title = title
        @id = options.fetch(:id, nil)
        @src = options.fetch(:src, '')
        @options = options.fetch(:options, [])
      end

      def to_adoc
        anchor = @id ? "[[#{@id}]]\n" : ""
        title = ".#{@title}\n" unless @title.empty?

        opts = ""
        if @options.any?
          opts = %{options="#{@options.join(',')}"}
        end

        [anchor, title, "video::", @src, "[", opts, "]"].join("")
      end
    end
  end
end
