# frozen_string_literal: true

module Coradoc
  module Model
    class TableCell < Base
      attribute :id, :string
      attribute :content, :string, default: -> { "" }
      attribute :colrowattr, :string, default: -> { "" }
      attribute :alignattr, :string, default: -> { "" }
      attribute :style, :string, default: -> { "" }
      attribute :anchor, Inline::Anchor, default: -> {
        id.nil? ? nil : Inline::Anchor.new(id)
      }

      asciidoc do
        map_content to: :content
        map_attribute "id", to: :id
        map_attribute "anchor", to: :anchor
      end

      def asciidoc?
        style.include?("a")
      end

      def to_asciidoc
        _anchor = anchor.nil? ? "" : anchor.to_asciidoc
        _content = simplify_block_content(content)
        _content = Coradoc::Generator.gen_adoc(_content)
        # Only try to postprocess elements that are text,
        # otherwise we could strip markup.
        if Coradoc.a_single?(content, Coradoc::Element::TextElement)
          _content = Coradoc.strip_unicode(_content)
        end

        "#{colrowattr}#{alignattr}#{style}| #{_anchor}#{_content}"
      end
    end
  end
end
