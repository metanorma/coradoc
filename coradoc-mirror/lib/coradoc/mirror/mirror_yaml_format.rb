# frozen_string_literal: true

require "yaml"

module Coradoc
  module Mirror
    # Format module for mirror YAML output.
    #
    # Registers with Coradoc so the CLI can discover it:
    #   Coradoc.convert(text, from: :asciidoc, to: :mirror_yaml)
    #   coradoc convert doc.adoc -t mirror_yaml
    module MirrorYamlFormat
      class << self
        # Output-only format — parsing from mirror YAML is not supported via
        # the format registry. Use Mirror::Node.from_h directly.
        def parse_to_core(input, options = {})
          raise Coradoc::UnsupportedFormatError,
                "Parsing from mirror YAML is not supported via the format registry. " \
                "Use Coradoc::Mirror::Node.from_h(YAML.safe_load(input)) directly."
        end

        # Accept CoreModel, serialize to Mirror YAML.
        def serialize(document, options = {})
          node = Coradoc::Mirror.transform(document)
          node.to_yaml
        end

        def serialize?
          true
        end

        def handles_model?(_model)
          false
        end
      end
    end
  end
end

Coradoc.register_format(:mirror_yaml, Coradoc::Mirror::MirrorYamlFormat,
                        extensions: %w[.mirror.yaml .mirror.yml])
