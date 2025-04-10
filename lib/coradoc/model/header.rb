# frozen_string_literal: true

module Coradoc
  module Model
    class Header < Base
      attribute :title, :string
      attribute :author, Coradoc::Model::Author
      attribute :revision, Coradoc::Model::Revision

      asciidoc do
        map_attribute "title", to: :title
        map_attribute "author", to: :author
        map_attribute "revision", to: :revision
      end

      def to_asciidoc
        adoc = "= #{title}\n"
        adoc << author.to_asciidoc if author
        adoc << revision.to_asciidoc if revision
        adoc
      end
    end
  end
end
