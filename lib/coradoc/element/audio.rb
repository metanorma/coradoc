module Coradoc
  module Element
    class Audio < Base
      attr_accessor :id, :title, :src, :options, :anchor, :attributes

      declare_children :id, :title, :anchor, :attributes

      def initialize(id: nil, title: "", src: "", attributes: AttributeList.new, line_break: "\n")
        @title = title
        @id = id
        @anchor = @id.nil? ? nil : Inline::Anchor.new(id: @id)
        @src = src
        @line_break = line_break
        @attributes = attributes
      end

      def to_adoc
        anchor = @anchor.nil? ? "" : "#{@anchor.to_adoc}\n"
        title = ".#{@title}\n" unless @title.empty?
        attrs = @attributes.empty? ? "[]" : @attributes.to_adoc
        [anchor, title, "audio::", @src, attrs].join + @line_break
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
