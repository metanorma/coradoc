# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Namespace for all AsciiDoc list types and their items.
      #
      # List Architecture:
      #   - List::Core - Common list functionality (base class)
      #   - List::Ordered - Numbered lists (1., 2., 3., etc.)
      #   - List::Unordered - Bulleted lists (*, **, etc.)
      #   - List::Definition - Labeled/definition lists (term:: definition)
      #   - List::Item - Item for ordered/unordered lists
      #   - List::DefinitionItem - Item for definition lists
      #   - List::Nestable - Mixin for nesting support
      #
      module List
        # Autoload list types lazily
        autoload :Core, 'coradoc/asciidoc/model/list/core'
        autoload :Nestable, 'coradoc/asciidoc/model/list/nestable'
        autoload :Ordered, 'coradoc/asciidoc/model/list/ordered'
        autoload :Unordered, 'coradoc/asciidoc/model/list/unordered'
        autoload :Definition, 'coradoc/asciidoc/model/list/definition'
        autoload :Item, 'coradoc/asciidoc/model/list/item'
        autoload :DefinitionItem, 'coradoc/asciidoc/model/list/definition_item'
      end
    end
  end
end
