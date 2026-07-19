# frozen_string_literal: true

module Coradoc
  module Reference
    class Address < Lutaml::Model::Serializable
      # Inter-document path — a document identifier plus optional fragment.
      # Matches document-ID-shaped barewords (uppercase + dash + digit,
      # e.g. "ELF-5005-1") and relative/absolute file paths
      # ("images/foo.png", "../shared/common.adoc"). Locality is carried
      # in fragment.
      #
      #   "ELF-5005-1"          => path target "ELF-5005-1"
      #   "ELF-5005-1#sec-3"    => path target "ELF-5005-1", fragment "sec-3"
      #   "images/foo.png"      => path target "images/foo.png"
      module Path
        module_function

        # Strict pattern used by +matches?+ — distinguishes path-shaped
        # barewords (uppercase + digit) from anchors.
        STRICT_PATTERN = /\A([A-Z][A-Z0-9_\-]*\d[\w\-]*)(?:#(.*))?\z/
        # Loose pattern used by +parse+ when the scheme is already chosen
        # (via hint). Accepts any non-empty target plus optional fragment.
        LOOSE_PATTERN = /\A([^#]+)(?:#(.*))?\z/

        def scheme_name
          :path
        end

        def matches?(raw)
          return false if raw.nil? || raw.empty?

          value = raw.to_s
          STRICT_PATTERN.match?(value) || value.include?('/')
        end

        def parse(raw)
          match = LOOSE_PATTERN.match(raw.to_s)
          raise Address::ParseError, "Invalid path: #{raw.inspect}" unless match

          Address.new(
            scheme: 'path',
            target: match[1],
            fragment: normalize_fragment(match[2])
          )
        end

        def serialize(address)
          base = address.target.to_s
          return base unless address.fragment && !address.fragment.empty?

          "#{base}##{address.fragment}"
        end

        def normalize_fragment(fragment)
          fragment&.empty? ? nil : fragment
        end
      end
    end
  end
end
