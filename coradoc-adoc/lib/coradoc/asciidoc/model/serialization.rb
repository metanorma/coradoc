# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Model
      # Serialization support for AsciiDoc models.
      #
      # This module registers the `asciidoc` format with Lutaml::Model,
      # enabling the `asciidoc do ... end` DSL in model classes.
      #
      # IMPORTANT: This module must be loaded BEFORE any model class
      # that uses the `asciidoc` DSL. It is loaded eagerly by model.rb
      # to ensure the format is registered early.
      #
      module Serialization
        # Load all serialization components eagerly (they're small and interdependent)
        require_relative 'serialization/errors'
        require_relative 'serialization/asciidoc_adapter'
        require_relative 'serialization/asciidoc_mapping_rule'
        require_relative 'serialization/asciidoc_mapping'
        require_relative 'serialization/asciidoc_transform'

        # Register the asciidoc format with Lutaml::Model
        # This enables the `asciidoc do ... end` DSL in model classes
        def self.register_format!
          Lutaml::Model::FormatRegistry.register(
            :asciidoc,
            mapping_class: AsciidocMapping,
            adapter_class: AsciidocAdapter,
            transformer: AsciidocTransform
          )
        end

        # Register format when this module is loaded
        register_format!
      end
    end
  end
end
