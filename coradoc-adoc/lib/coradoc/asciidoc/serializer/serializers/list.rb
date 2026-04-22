# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Serializer
      module Serializers
        # Autoload list serializers
        module List
          autoload :Core, 'coradoc/asciidoc/serializer/serializers/list/core'
          autoload :Definition, 'coradoc/asciidoc/serializer/serializers/list/definition'
          autoload :DefinitionItem, 'coradoc/asciidoc/serializer/serializers/list/definition_item'
          autoload :Item, 'coradoc/asciidoc/serializer/serializers/list/item'
          autoload :Ordered, 'coradoc/asciidoc/serializer/serializers/list/ordered'
          autoload :Unordered, 'coradoc/asciidoc/serializer/serializers/list/unordered'
        end
      end
    end
  end
end
