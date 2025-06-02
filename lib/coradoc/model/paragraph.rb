# frozen_string_literal: true

module Coradoc
  module Model
    class Paragraph < Attached
      include Coradoc::Model::Anchorable

      attribute :id, :string
      # TODO: polymorphic with :string and TextElement?
      attribute :content,
                Lutaml::Model::Serializable,
                collection: true,
                initialize_empty: true,
                polymorphic: [
                  # :string,
                  Lutaml::Model::Type::String,
                  Coradoc::Model::TextElement,
                ]
      attribute :title, :string
      attribute :attributes, AttributeList, default: -> { AttributeList.new }
      attribute :tdsinglepara, :boolean, default: -> { false }

      asciidoc do
        map_model to: Coradoc::Element::Paragraph
        map_content to: :content
        map_attribute "id", to: :id
        map_attribute "title", to: :title
        map_attribute "attributes", to: :attributes
        map_attribute "anchor", to: :anchor
      end

      def to_asciidoc
        _title = title.nil? ? "" : ".#{Coradoc::Generator.gen_adoc(title)}\n"
        _anchor = gen_anchor
        attrs = attributes.nil? || attributes.empty? ? "" : "#{attributes.to_asciidoc}\n"
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
