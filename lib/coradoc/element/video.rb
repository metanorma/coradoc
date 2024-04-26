module Coradoc
  module Element
    class Video
      attr_reader :id, :title, :src, :options

      def initialize(title, options = {})
        @title = title
        @id = options.fetch(:id, nil)
        @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
        @src = options.fetch(:src, '')
        @attributes = options.fetch(:attributes, [])
        # @attributes.add_valid_named('opts')
      end

      def to_adoc
        anchor = @anchor.nil? ? "" : "#{@anchor.to_adoc}\n"
        title = ".#{@title}\n" unless @title.empty?
        attrs = @attributes.empty? ? "\[\]" : @attributes.to_adoc
        [anchor, title, "video::", @src, attrs].join("")
      end
    end
  end
end
