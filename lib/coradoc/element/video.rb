module Coradoc
  module Element
    class Video < Base
      attr_accessor :id, :title, :src, :options

      declare_children :id, :anchor, :attributes

      def initialize(title, options = {})
        @title = title
        @id = options.fetch(:id, nil)
        @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
        @src = options.fetch(:src, "")
        @attributes = options.fetch(:attributes, AttributeList.new)
        if @attributes.any?
          @attributes.validate_positional(VALIDATORS_POSITIONAL)
          @attributes.validate_named(VALIDATORS_NAMED)
        end
      end

      def to_adoc
        anchor = @anchor.nil? ? "" : "#{@anchor.to_adoc}\n"
        title = ".#{@title}\n" unless @title.empty?
        attrs = @attributes.to_adoc
        [anchor, title, "video::", @src, attrs].join("")
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
