# frozen_string_literal: true

module Coradoc
  module Model
    module List
      class Core < Nestable
        include Coradoc::Model::Anchorable

        attribute :id, :string
        attribute :prefix, :string
        # attribute :anchor, Inline::Anchor, default: -> {
        #   id.nil? ? nil : Inline::Anchor.new(id)
        # }
        attribute :items, ListItem, collection: true, initialize_empty: true
        attribute :ol_count, :integer, default: -> { 1 }
        attribute :attrs, AttributeList, default: -> { AttributeList.new }
        attribute :marker, :string

        asciidoc do
          map_attribute "id", to: :id
          map_attribute "anchor", to: :anchor
          map_attribute "prefix", to: :prefix
          map_attribute "items", to: :items
          map_attribute "ol_count", to: :ol_count
          map_attribute "attrs", to: :attrs
          map_attribute "marker", to: :marker
        end

        def to_asciidoc
          _anchor = anchor.nil? ? "" : anchor.to_asciidoc.to_s
          _attrs = attrs.to_asciidoc(false).to_s
          content = "\n"
          items.each do |item|
            c = Coradoc::Generator.gen_adoc(item)
            if !c.empty?
              # If there's a list inside a list directly, we want to
              # skip adding an empty list item.
              # See: https://github.com/metanorma/coradoc/issues/96
              unless item.is_a? List::Core
                content << prefix.to_s
                content << " " if c[0] != " "
              end
              content << c
            end
          end
          "\n#{_anchor}#{_attrs}" + content
        end
      end
    end
  end
end
