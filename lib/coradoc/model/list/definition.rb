# frozen_string_literal: true

module Coradoc
  module Model
    module List
      class Definition < Base
        attribute :items, ListItem, collection: true, initialize_empty: true
        attribute :delimiter, :string, default: -> { "::" }

        asciidoc do
          map_attribute "items", to: :items
          map_attribute "delimiter", to: :delimiter
        end

        def prefix
          delimiter
        end

        def to_asciidoc
          content = "\n"
          items.each do |item|
            content << item.to_asciidoc(delimiter)
          end
          content
        end
      end
    end
  end
end
