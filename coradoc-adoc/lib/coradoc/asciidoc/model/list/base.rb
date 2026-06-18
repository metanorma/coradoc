# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module List
        # Shared base class for all list container types.
        #
        # Every list flavor (Core, Definition, and any future ones) inherits
        # the universal list-level attributes from this class:
        #
        #   - +id+    optional anchor identifier (inherited from Model::Base)
        #   - +attrs+ block attribute list, e.g. +[%hardbreaks]+ or +[#my-id]+
        #
        # Subclasses declare their own +items+ with the appropriate item type
        # (List::Item for ordered/unordered, List::DefinitionItem for definition)
        # plus any flavor-specific attributes (marker, prefix, delimiter, ...).
        #
        # @!attribute [r] attrs
        #   @return [Coradoc::AsciiDoc::Model::AttributeList] Additional list
        #     attributes parsed from the +[...]+ block header preceding the list
        class Base < Coradoc::AsciiDoc::Model::Base
          include Coradoc::AsciiDoc::Model::Anchorable

          attribute :attrs,
                    Coradoc::AsciiDoc::Model::AttributeList,
                    default: -> { Coradoc::AsciiDoc::Model::AttributeList.new }

          asciidoc do
            map_attribute 'id', to: :id
            map_attribute 'attrs', to: :attrs
          end

          def block_level?
            true
          end
        end
      end
    end
  end
end
