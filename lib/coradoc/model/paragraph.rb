# frozen_string_literal: true

module Coradoc
  module Model
    class Paragraph < Base
      attribute :id, :string
      attribute :content, :string
      attribute :title, :string
      attribute :attributes, AttributeList, default: -> { AttributeList.new }
      attribute :anchor, Inline::Anchor, default: -> { id.nil? ? nil : Inline::Anchor.new(id) }
      attribute :tdsinglepara, :boolean, default: -> { false }

      asciidoc do
        map_content to: :content
        map_attribute "id", to: :id
        map_attribute "title", to: :title
        map_attribute "attributes", to: :attributes
        map_attribute "anchor", to: :anchor
      end

      def to_asciidoc
        _title = title.nil? ? "" : ".#{Coradoc::Generator.gen_adoc(title)}\n"
        _anchor = anchor.nil? ? "" : "#{anchor.to_adoc}\n"
        attrs = attributes.nil? ? "" : "#{attributes.to_adoc}\n"
        if tdsinglepara
          "#{_title}#{_anchor}" << Coradoc.strip_unicode(Coradoc::Generator.gen_adoc(content))
        else
          "\n\n#{_title}#{_anchor}#{attrs}" << Coradoc.strip_unicode(Coradoc::Generator.gen_adoc(content)) << "\n\n"
        end
      end
    end
  end
end
