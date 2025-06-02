# frozen_string_literal: true

module Coradoc
  module Model
    class Glossaries < Base
      attribute :items, :string, collection: true

      asciidoc do
        map_model to: Coradoc::Element::Glossaries
        map_attribute "items", to: :items
      end
    end
  end
end
