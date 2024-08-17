module Coradoc
  module Element
    module Image
      class Core < Base
        attr_accessor :title, :id, :src, :attributes

        declare_children :id, :src, :title, :attributes

        def initialize(title, id, src, options = {})
          @title = title
          @id = id
          @anchor = @id.nil? ? nil : Inline::Anchor.new(@id)
          @src = src
          @attributes = options.fetch(:attributes, AttributeList.new)
          @annotate_missing = options.fetch(:annotate_missing, nil)
          @title = options.fetch(:title, nil) unless @title
          if @attributes.any?
            @attributes.validate_positional(VALIDATORS_POSITIONAL)
            @attributes.validate_named(VALIDATORS_NAMED)
          end
          @line_break = options.fetch(:line_break, "")
        end

        def to_adoc
          missing = "// FIXME: Missing image: #{@annotate_missing}\n" if @annotate_missing
          anchor = @anchor.nil? ? "" : "#{@anchor.to_adoc}\n"
          title = ".#{@title}\n" unless @title.to_s.empty?
          attrs = @attributes_macro.to_adoc
          [missing, anchor, title, "image", @colons, @src, attrs, @line_break].join("")
        end

        extend AttributeList::Matchers
        VALIDATORS_POSITIONAL = [
          [:alt, String],
          [:width, Integer],
          [:height, Integer],
        ]

        VALIDATORS_NAMED = {
          id: String,
          alt: String,
          fallback: String,
          title: String,
          width: Integer,
          height: Integer,
          link: String, # change to that URI regexp
          window: String,
          scale: Integer,
          scaledwidth: /\A[0-9]{1,2}%\z/,
          pdfwidth: /\A[0-9]+vw\z/,
          role: many(/.*/, "left", "right", "th", "thumb", "related", "rel"),
          opts: many("nofollow", "noopener", "inline", "interactive"),
        }
      end
    end
  end
end
