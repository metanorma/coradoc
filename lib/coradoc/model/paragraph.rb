# frozen_string_literal: true

module Coradoc
  module Model
    class Paragraph < Attached
      include Coradoc::Model::Anchorable

      attribute :id, :string
      attribute :content, :string
      attribute :title, :string
      attribute :attrs, AttributeList, default: -> { AttributeList.new }
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
        _anchor = anchor.nil? ? "" : "#{anchor.to_asciidoc}\n"
        attrs = attributes.nil? ? "" : "#{attributes.to_asciidoc}\n"

        if tdsinglepara
          "#{_title}#{_anchor}" <<
            Coradoc.strip_unicode(Coradoc::Generator.gen_adoc(content))
        else
          "\n\n#{_title}#{_anchor}#{attrs}" <<
            Coradoc.strip_unicode(Coradoc::Generator.gen_adoc(content)) <<
            "\n\n"
        end
      end
    end
  end
end
