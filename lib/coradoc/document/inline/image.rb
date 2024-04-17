module Coradoc
  module Document
    module Inline
      class Image
        attr_reader :id, :title, :src, :alt, :width, :height
        def initialize(options = ())
          @id = options.fetch(:id, nil)
          @title = options.fetch(:title, nil)
          @src = options.fetch(:src, nil)
          @alt = options.fetch(:alt, nil)
          @width = options.fetch(:width, nil)
          @height = options.fetch(:height, nil)
        end
        def to_adoc
          anchor = @id ? "[[#{@id}]]\n" : ""
          title = ".#{@title}\n" unless @title.empty?
          attrs = @alt
          attrs = "\"\"" if (@width || @height) && @alt.nil?
          attrs += ",#{@width}" if @width
          attrs += ",#{@height}" if @width && @height
          [anchor, title, "image::", src, "[", attrs, "]"].join("")
        end
      end
    end
  end
end
