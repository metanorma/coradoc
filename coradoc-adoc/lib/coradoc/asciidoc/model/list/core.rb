# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module List
        # Base class for list elements in AsciiDoc documents.
        #
        # Lists are container elements that hold list items and provide
        # functionality for different list types (ordered, unordered, definition).
        #
        # @!attribute [r] id
        #   @return [String, nil] Optional identifier for the list
        # @!attribute [r] prefix
        #   @return [String, nil] List marker prefix (e.g., "*", "*", "**", etc.)
        # @!attribute [r] items
        #   @return [Array<ListItem>] List items in this list
        # @!attribute [r] ol_count
        # @return [Integer] Ordered list nesting level
        # @!attribute [r] attrs
        #   @return [AttributeList] Additional list attributes
        # @!attribute [r] marker
        #   @return [String, nil] The marker character used for this list
        #
        # @example Create an unordered list
        #   list = Coradoc::AsciiDoc::Model::List::Unordered.new
        #   list.items << Coradoc::AsciiDoc::Model::List::Item.new("Item 1")
        #
        class Core < Nestable
          include Coradoc::AsciiDoc::Model::Anchorable

          attribute :id, :string
          attribute :prefix, :string
          # attribute :anchor, Inline::Anchor, default: -> {
          #   id.nil? ? nil : Inline::Anchor.new(id)
          # }
          attribute :items, Coradoc::AsciiDoc::Model::List::Item, collection: true, initialize_empty: true
          attribute :ol_count, :integer, default: -> { 1 }
          attribute :attrs, Coradoc::AsciiDoc::Model::AttributeList, default: lambda {
            Coradoc::AsciiDoc::Model::AttributeList.new
          }
          attribute :marker, :string

          asciidoc do
            map_attribute 'id', to: :id
            map_attribute 'anchor', to: :anchor
            map_attribute 'prefix', to: :prefix
            map_attribute 'items', to: :items
            map_attribute 'ol_count', to: :ol_count
            map_attribute 'attrs', to: :attrs
            map_attribute 'marker', to: :marker
          end
        end
      end
    end
  end
end
