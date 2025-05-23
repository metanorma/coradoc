module Coradoc
  module Element
    class Video < Base
      attr_accessor :id, :title, :src, :options

      declare_children :id, :anchor, :attributes

      def initialize(id: nil, title: "", src: "", attributes: AttributeList.new, line_break: "\n")
        @title = title
        @id = id
        @anchor = @id.nil? ? nil : Inline::Anchor.new(id: @id)
        @src = src
        @line_break = line_break
        @attributes = attributes
        if @attributes.any?
          @attributes.validate_positional(VALIDATORS_POSITIONAL)
          @attributes.validate_named(VALIDATORS_NAMED)
        end
      end

      def to_adoc
        anchor = @anchor.nil? ? "" : "#{@anchor.to_adoc}\n"
        title = ".#{@title}\n" unless @title.empty?
        attrs = @attributes.to_adoc
        [anchor, title, "video::", @src, attrs].join + @line_break
      end

      extend AttributeList::Matchers
      VALIDATORS_POSITIONAL = [
        [:alt, String],
        [:width, Integer],
        [:height, Integer],
      ].freeze

      VALIDATORS_NAMED = {
        title: String,
        poster: String,
        width: Integer,
        height: Integer,
        start: Integer,
        end: Integer,
        theme: one("dark", "light"),
        lang: /[a-z]{2,3}(?:-[A-Z]{2})?/,
        list: String,
        playlist: String,
        options: many("autoplay", "loop", "modest",
                      "nocontrols", "nofullscreen", "muted"),
      }.freeze
    end
  end
end
