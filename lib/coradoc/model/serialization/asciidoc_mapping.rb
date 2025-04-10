# frozen_string_literal: true

module Coradoc
  module Model
    module Serialization

      # Define the DSL for defining mappings in Asciidoc format
      class AsciidocMapping < Lutaml::Model::Mapping
        attr_reader :mappings

        def initialize
          super
          @mappings = []
        end

        def map_content(to:)
          add_mapping("__content", to, field_type: :content)
        end

        def map_attribute(name, to:, render_nil: false)
          add_mapping(
            name,
            to,
            field_type: :attributes,
            render_nil: render_nil,
          )
        end

        private

        def add_mapping(name, to, **options)
          @mappings << AsciidocMappingRule.new(
            name, to: to, **options
          )
        end

      end
    end
  end
end
