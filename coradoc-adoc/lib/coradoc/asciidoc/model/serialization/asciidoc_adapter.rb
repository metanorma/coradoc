# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      module Serialization
        # Adapter for AsciiDoc serialization in Lutaml::Model format registry.
        #
        # This is a standalone adapter class that delegates to Coradoc's
        # parsing infrastructure. It does NOT inherit from Base to avoid
        # circular dependencies with the format registration system.
        #
        class AsciidocAdapter
          # Delegate to Model::Document for AST creation
          def self.from_ast(elements)
            # Lazy reference to avoid loading Document before format is registered
            Coradoc::AsciiDoc::Model::Document.from_ast(elements)
          end

          # Delegate to Coradoc.parse for parsing
          def self.parse(string)
            Coradoc.parse(string)
          end
        end
      end
    end
  end
end
