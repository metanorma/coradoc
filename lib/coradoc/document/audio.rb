module Coradoc
  module Document
    class Audio
      attr_reader :id, :title, :src, :options, :anchor

      def initialize(title, options = {})
        @title = title
        @id = options.fetch(:id, nil)
        @anchor = Inline::Anchor.new(@id) if @id
        @src = options.fetch(:src, '')
        @options = options.fetch(:options, [])
      end

      def to_adoc
        anchor = @anchor.nil? ? "" : "#{@anchor.to_adoc}\n"
        title = ".#{@title}\n" unless @title.empty?

        opts = ""
        if @options.any?
          opts = %{options="#{@options.join(',')}"}
        end

        [anchor, title, "audio::", @src, "[", opts, "]"].join("")
      end
    end
  end
end
