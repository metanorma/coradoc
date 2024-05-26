module Coradoc
  module Element
    module Image
      class Core < Base
        attr_accessor :title, :id, :src, :attributes

        declare_children :id, :src, :title, :attributes

        def initialize(title, id, src, options = {})
          @title = title
          @id = id
          @anchor = @id.nil? ? nil : Coradoc::Element::Inline::Anchor.new(@id)
          @src = src
          @attributes = options.fetch(:attributes, AttributeList.new)
          @title = options.fetch(:title, nil)
          if @attributes.any?
            @attributes.validate_positional(VALIDATORS_POSITIONAL)
            @attributes.validate_named(VALIDATORS_NAMED)
          end
        end

        def to_adoc
          anchor = @anchor.nil? ? "" : "#{@anchor.to_adoc}\n"
          title = ".#{@title}\n" unless @title.to_s.empty?
          attrs = @attributes.to_adoc
          [anchor, title, "image", @colons, @src, attrs].join("")
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
