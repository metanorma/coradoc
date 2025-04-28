# frozen_string_literal: true

module Coradoc
  module Model
    module List
      class Definition < Base
        attribute :items, Coradoc::Model::Base, polymorphic: [ListItem,
        Coradoc::Model::ListItemDefinition], collection: true, initialize_empty: true
        attribute :delimiter, :string, default: -> { "::" }

        asciidoc do
          map_attribute "items", to: :items
          map_attribute "delimiter", to: :delimiter
        end

        def prefix
          delimiter
        end

        def to_asciidoc
          content = "\n".dup
          items.each do |item|
            content << item.to_asciidoc(delimiter: delimiter)
          end
          content
        end
      end
    end
  end
end
