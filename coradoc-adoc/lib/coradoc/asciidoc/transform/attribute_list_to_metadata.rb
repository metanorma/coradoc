# frozen_string_literal: true

module Coradoc
  module AsciiDoc
    module Transform
      # Single source of truth for AsciiDoc Model::AttributeList ->
      # CoreModel::Metadata conversion (DRY/MECE).
      #
      # Promotes the first positional attribute to `style` and the
      # `role=` named attribute to `role`, matching the AsciiDoc
      # block-header semantics that downstream consumers (coradoc-mirror)
      # dispatch on to pick a JS section type (annex, abstract, ...).
      #
      # Returns nil for anything that isn't a typed AttributeList so
      # callers can pass through optional/missing inputs without an
      # extra guard.
      module AttributeListToMetadata
        module_function

        def call(list)
          return nil unless list.is_a?(Coradoc::AsciiDoc::Model::AttributeList)

          metadata = Coradoc::CoreModel::Metadata.new
          first_positional = list.positional.first
          metadata['style'] = first_positional.value if first_positional
          named_role = list.named.find { |n| n.name == 'role' }
          metadata['role'] = named_role.value.first if named_role&.value&.any?
          metadata
        end
      end
    end
  end
end
