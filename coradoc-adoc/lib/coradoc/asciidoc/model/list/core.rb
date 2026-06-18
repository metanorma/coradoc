# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module List
        # Base class for ordered/unordered lists.
        #
        # Inherits universal list attributes (id, attrs) from List::Base and
        # adds the marker-related attributes specific to bulleted/numbered lists.
        #
        # @!attribute [r] prefix
        #   @return [String, nil] List marker prefix (e.g., "*", "**", etc.)
        # @!attribute [r] items
        #   @return [Array<ListItem>] List items in this list
        # @!attribute [r] ol_count
        # @return [Integer] Ordered list nesting level
        # @!attribute [r] marker
        #   @return [String, nil] The marker character used for this list
        #
        # @example Create an unordered list
        #   list = Coradoc::AsciiDoc::Model::List::Unordered.new
        #   list.items << Coradoc::AsciiDoc::Model::List::Item.new("Item 1")
        #
        class Core < Nestable
          attribute :prefix, :string
          attribute :items, Coradoc::AsciiDoc::Model::List::Item, collection: true, initialize_empty: true
          attribute :ol_count, :integer, default: -> { 1 }
          attribute :marker, :string

          asciidoc do
            map_attribute 'prefix', to: :prefix
            map_attribute 'items', to: :items
            map_attribute 'ol_count', to: :ol_count
            map_attribute 'marker', to: :marker
          end
        end
      end
    end
  end
end
