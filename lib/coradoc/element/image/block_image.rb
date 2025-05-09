module Coradoc
  module Element
    module Image
      class BlockImage < Core
        def initialize(title, id, src, options = {})
          super
          @colons = "::"
        end

        def to_adoc
          missing = "// FIXME: Missing image: #{@annotate_missing}\n" if @annotate_missing
          anchor = @anchor.nil? ? "" : "#{@anchor.to_adoc}\n"
          title = ".#{@title}\n" unless @title.to_s.empty?
          attrs = @attributes.to_adoc
          [missing, anchor, title, "image", @colons, @src, attrs,
           @line_break].join
        end

        def validate_named
          @attributes.validate_named(VALIDATORS_NAMED, VALIDATORS_NAMED_BLOCK)
        end

        extend AttributeList::Matchers
        VALIDATORS_NAMED_BLOCK = {
          caption: String,
          align: one("left", "center", "right"),
          float: one("left", "right"),
        }.freeze
      end
    end
  end
end
