module Coradoc
  module Element
    module Image
      class Core
        attr_reader :title, :id, :src, :attributes

        def initialize(title, id, src, options = ())
          @title = title
          @id = id
          @anchor = @id.nil? ? nil : Coradoc::Element::Inline::Anchor.new(@id)
          @src = src
          @attributes = options.fetch(:attributes, [])
          @title = options.fetch(:title, nil)
        end

        def to_adoc
          anchor = @anchor.nil? ? "" : "#{@anchor.to_adoc}\n"
          title = ".#{@title}\n" unless @title.to_s.empty?
          attrs = @attributes.empty? ? "\[\]" : @attributes.to_adoc
          [anchor, title, "image", @colons, @src, attrs].join("")
        end
      end
    end
  end
end
