module Coradoc
  module Element
    class Audio < Base
      attr_accessor :id, :title, :src, :options, :anchor, :attributes

      declare_children :id, :title, :anchor, :attributes

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

      extend AttributeList::Matchers
      VALIDATORS_NAMED = {
        title: String,
        start: Integer,
        end: Integer,
        options: many("nofollow", "noopener", "inline", "interactive"),
        opts: many("nofollow", "noopener", "inline", "interactive"),
      }.freeze
    end
  end
end
