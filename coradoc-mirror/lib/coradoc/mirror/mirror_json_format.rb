# frozen_string_literal: true

require "json"

module Coradoc
  module Mirror
    # Format module for mirror JSON output.
    #
    # Registers with Coradoc so the CLI can discover it:
    #   Coradoc.convert(text, from: :asciidoc, to: :mirror_json)
    #   coradoc convert doc.adoc -t mirror_json
    module MirrorJsonFormat
      class << self
        # Output-only format — parsing from mirror JSON is not supported via
        # the format registry. Use Mirror::Node.from_h directly.
        def parse_to_core(input, options = {})
          raise Coradoc::UnsupportedFormatError,
                "Parsing from mirror JSON is not supported via the format registry. " \
                "Use Coradoc::Mirror::Node.from_h(JSON.parse(input)) directly."
        end

        # Accept CoreModel, serialize to Mirror JSON.
        def serialize(document, options = {})
          pretty = options[:pretty] != false
          node = Coradoc::Mirror.transform(document)
          node.to_json(pretty: pretty)
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

Coradoc.register_format(:mirror_json, Coradoc::Mirror::MirrorJsonFormat,
                        extensions: %w[.mirror.json])
