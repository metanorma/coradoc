# frozen_string_literal: true

module Coradoc
  module Model
    class Section < Base
      include Coradoc::Model::Anchorable

      attribute :id, :string
      attribute :content, :string
      attribute :title, Coradoc::Model::Title
      attribute :attrs,
                Coradoc::Model::NamedAttribute,
                collection: true,
                initialize_empty: true
      attribute :contents,
                Coradoc::Model::Paragraph,
                collection: true,
                initialize_empty: true
      attribute :sections,
                Coradoc::Model::Section,
                collection: true,
                initialize_empty: true
      # attribute :anchor, Coradoc::Model::Inline::Anchor

      asciidoc do
        map_content to: :content
        map_attribute "id", to: :id
        map_attribute "title", to: :title
        map_attribute "attrs", to: :attrs
        map_attribute "contents", to: :contents
        map_attribute "sections", to: :sections
        map_attribute "anchor", to: :anchor
      end
    end
  end
end
