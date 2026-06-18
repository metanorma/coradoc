# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module List
        # Definition list container. Inherits universal list attributes
        # (id, attrs) from List::Base.
        #
        # @!attribute [r] items
        #   @return [Array<DefinitionItem>] Definition items in this list
        # @!attribute [r] delimiter
        #   @return [String] Delimiter indicating nesting depth ('::', ':::', ...)
        class Definition < Base
          attribute :items,
                    Coradoc::AsciiDoc::Model::Base,
                    polymorphic: [Coradoc::AsciiDoc::Model::List::DefinitionItem],
                    collection: true,
                    initialize_empty: true
          attribute :delimiter, :string, default: -> { '::' }

          asciidoc do
            map_attribute 'items', to: :items
            map_attribute 'delimiter', to: :delimiter
          end

          def prefix
            delimiter
          end
        end
      end
    end
  end
end
