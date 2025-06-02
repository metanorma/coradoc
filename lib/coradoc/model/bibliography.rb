# frozen_string_literal: true

module Coradoc
  module Model
    class Bibliography < Base
      include Coradoc::Model::Anchorable

      attribute :id, :string
      attribute :title, :string
      attribute :entries, BibliographyEntry, collection: true

      asciidoc do
        map_model to: Coradoc::Element::Bibliography
        map_attribute "id", to: :id
        map_attribute "title", to: :title
        map_attribute "entries", to: :entries
        map_attribute "anchor", to: :anchor
      end

      def to_asciidoc
        adoc = "#{gen_anchor}\n"
        adoc << "[bibliography]"
        adoc << "== #{title}\n\n"
        entries&.each do |entry|
          adoc << "#{entry.to_asciidoc}\n"
        end
        adoc
      end
    end
  end
end
