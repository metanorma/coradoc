# frozen_string_literal: true

require_relative "serialization/errors"
require_relative "serialization/asciidoc_document"
require_relative "serialization/asciidoc_document_entry"
require_relative "serialization/asciidoc_adapter"
require_relative "serialization/asciidoc_mapping_rule"
require_relative "serialization/asciidoc_mapping"
require_relative "serialization/asciidoc_transform"

module Coradoc
  module Model
    module Serialization
      # Register AsciiDoc format
      Lutaml::Model::FormatRegistry.register(
        :asciidoc,
        mapping_class: AsciidocMapping,
        adapter_class: AsciidocAdapter,
        transformer: AsciidocTransform,
      )
    end
  end
end
