# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module List
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
