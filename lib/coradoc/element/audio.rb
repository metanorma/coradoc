module Coradoc
  module Element
    class Audio
      attr_reader :id, :title, :src, :options, :anchor

      def initialize(title, options = {})
        @title = title
        @id = options.fetch(:id, nil)
        @anchor = Inline::Anchor.new(@id) if @id
        @src = options.fetch(:src, "")
        @attributes = options.fetch(:attributes, [])
      end

      def to_adoc
        anchor = @anchor.nil? ? "" : "#{@anchor.to_adoc}\n"
        title = ".#{@title}\n" unless @title.empty?
        attrs = @attributes.empty? ? "\[\]" : @attributes.to_adoc
        [anchor, title, "audio::", @src, attrs].join("")
      end
    end
  end
end
